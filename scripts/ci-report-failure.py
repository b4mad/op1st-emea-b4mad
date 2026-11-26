#!/usr/bin/env python3
"""Open or update a forge issue for a failed Tekton pipeline.

Run by .tekton/tasks/report-failure.yaml as a `finally` task. Stdlib only, so it
runs in a bare python image. Reads its inputs from the environment.
"""

import json
import os
import re
import ssl
import sys
import urllib.error
import urllib.parse
import urllib.request
import uuid

FORGE = "https://git.b4mad.industries"
SA_DIR = "/var/run/secrets/kubernetes.io/serviceaccount"
# Forgejo rejects very large comment bodies; stay well under and attach
# the full log as a file when a step's log is longer than this.
INLINE_LIMIT = 50_000
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")
REDACTIONS = [
    (
        re.compile(
            r"-----BEGIN [A-Z ]*PRIVATE KEY-----.*?-----END [A-Z ]*PRIVATE KEY-----",
            re.S,
        ),
        "-----[private key redacted]-----",
    ),
    (re.compile(r"(?i)(authorization:\s*(?:bearer|token|basic)\s+)\S+"), r"\1***"),
    (
        re.compile(
            r"(?i)\b([A-Za-z0-9_.-]*(?:token|secret|passw(?:or)?d|api[_-]?key)[A-Za-z0-9_.-]*\s*[=:]\s*)[^\s'\"]+"
        ),
        r"\1***",
    ),
    (re.compile(r"(://[^/\s:@]+:)[^@\s/]+@"), r"\1***@"),
]


def redact(text, extra=()):
    text = ANSI.sub("", text)
    for pattern, repl in REDACTIONS:
        text = pattern.sub(repl, text)
    for secret in extra:
        if secret:
            text = text.replace(secret, "***")
    return text


def fence(text):
    """A code fence longer than any backtick run inside `text`."""
    longest = max((len(m) for m in re.findall(r"`+", text)), default=0)
    return "`" * max(3, longest + 1)


class Http:
    def __init__(self, base, headers, ctx=None):
        self.base, self.headers, self.ctx = base, headers, ctx

    def call(self, method, path, body=None, raw=False, data=None, headers=None):
        hdrs = dict(self.headers, **(headers or {}))
        if body is not None:
            data = json.dumps(body).encode()
            hdrs["Content-Type"] = "application/json"
        req = urllib.request.Request(
            self.base + path, data=data, method=method, headers=hdrs
        )
        with urllib.request.urlopen(req, timeout=60, context=self.ctx) as resp:
            payload = resp.read()
        return (
            payload.decode("utf-8", "replace")
            if raw
            else json.loads(payload or b"null")
        )


def k8s_client():
    host = os.environ["KUBERNETES_SERVICE_HOST"]
    port = os.environ.get("KUBERNETES_SERVICE_PORT", "443")
    with open(f"{SA_DIR}/token") as fh:
        token = fh.read().strip()
    ctx = ssl.create_default_context(cafile=f"{SA_DIR}/ca.crt")
    return Http(f"https://{host}:{port}", {"Authorization": f"Bearer {token}"}, ctx)


def failed_steps(k8s, ns, run):
    """[(pipeline_task, reason, message, [(container, step_name, exit_code)], pod)]"""
    sel = urllib.parse.quote(f"tekton.dev/pipelineRun={run}")
    taskruns = k8s.call(
        "GET", f"/apis/tekton.dev/v1/namespaces/{ns}/taskruns?labelSelector={sel}"
    )["items"]
    out = []
    for tr in taskruns:
        status = tr.get("status", {})
        cond = (status.get("conditions") or [{}])[0]
        # Cancelled runs (cancel-in-progress superseding a push) are not failures.
        if cond.get("status") != "False" or cond.get("reason") == "TaskRunCancelled":
            continue
        steps = status.get("steps", [])
        bad = [
            (s.get("container"), s.get("name"), s["terminated"]["exitCode"])
            for s in steps
            if s.get("terminated", {}).get("exitCode", 0) != 0 and s.get("container")
        ]
        if not bad:  # timeout / pod-level failure: no step carries the blame, dump all
            bad = [
                (
                    s.get("container"),
                    s.get("name"),
                    s.get("terminated", {}).get("exitCode"),
                )
                for s in steps
                if s.get("container")
            ]
        out.append(
            (
                tr["metadata"]
                .get("labels", {})
                .get("tekton.dev/pipelineTask", tr["metadata"]["name"]),
                cond.get("reason", ""),
                cond.get("message", ""),
                bad,
                status.get("podName"),
            )
        )
    return out


def step_log(k8s, ns, pod, container):
    try:
        return k8s.call(
            "GET",
            f"/api/v1/namespaces/{ns}/pods/{pod}/log?container={container}",
            raw=True,
        )
    except Exception as exc:  # pod pruned, RBAC, ...
        return f"(log unavailable: {exc})"


def build_issue(env, pipeline, failures):
    sha = env["REVISION"]
    repo = env["REPO"]
    lines = [
        f"The Tekton pipeline **{pipeline}** failed. castra: please investigate.",
        "",
        "| | |",
        "|---|---|",
        f"| Commit | [`{sha[:8]}`]({FORGE}/{repo}/commit/{sha}) |",
        f"| Branch | `{env.get('SOURCE_BRANCH') or 'unknown'}` |",
        f"| Event | `{env.get('EVENT_TYPE') or 'unknown'}` |",
        f"| PipelineRun | `{env['PIPELINERUN_NAME']}` in `{env['PIPELINERUN_NAMESPACE']}` (nostromo) |",
        "",
        "## What failed",
        "",
    ]
    for task, reason, message, bad, _pod in failures:
        steps = ", ".join(f"`{name}` (exit {code})" for _c, name, code in bad)
        lines += [
            f"- Task `{task}`, step {steps}: {reason}",
            f"  > {message.splitlines()[0] if message else 'no message'}",
        ]
    lines += [
        "",
        "The log of each failed step is attached below as a comment, redacted for secrets.",
        "",
        "## Where to start",
        "",
        "- `code-scans` runs gitleaks (findings are redacted with --redact); "
        "in the cluster); `kustomize-validate` runs `kustomize build` on "
        "`manifests/environments/{nostromo,phobos}` and `manifests/applications`. "
        "Reproduce locally with the same command.",
        "- A failure in `clone-source` is usually the forge "
        f"({FORGE}), not this repo: check that it answers first.",
        f"- Re-read the run: `oc get pipelinerun -n {env['PIPELINERUN_NAMESPACE']} {env['PIPELINERUN_NAME']} -o yaml`.",
        "",
        "_Opened automatically by `.tekton/tasks/report-failure.yaml`._",
    ]
    return "\n".join(lines)


def log_comments(task, step, code, log):
    """[(comment_body, attachment_text_or_None)] for one failed step."""
    head = f"### Log of step `{step}` in task `{task}` (exit {code})\n\n"
    if len(log) <= INLINE_LIMIT:
        f = fence(log)
        return [(f"{head}{f}text\n{log}\n{f}", None)]
    tail = log[-INLINE_LIMIT:]
    f = fence(tail)
    note = f"The log is {len(log)} characters long. The last {INLINE_LIMIT} are shown. The full log is attached.\n\n"
    return [(f"{head}{note}{f}text\n{tail}\n{f}", log)]


def attach(cb, repo, comment_id, name, text):
    boundary = uuid.uuid4().hex
    body = (
        f'--{boundary}\r\nContent-Disposition: form-data; name="attachment"; filename="{name}"\r\n'
        f"Content-Type: text/plain\r\n\r\n{text}\r\n--{boundary}--\r\n"
    ).encode()
    cb.call(
        "POST",
        f"/api/v1/repos/{repo}/issues/comments/{comment_id}/assets?name={urllib.parse.quote(name)}",
        data=body,
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )


def label_ids(cb, repo, names):
    found, page = {}, 1
    while True:
        batch = cb.call("GET", f"/api/v1/repos/{repo}/labels?limit=50&page={page}")
        found.update({lbl["name"]: lbl["id"] for lbl in batch})
        if len(batch) < 50:
            break
        page += 1
    ids = []
    for name in names:
        if name in found:
            ids.append(found[name])
        else:
            print(f"warning: label {name!r} does not exist in {repo}, skipped")
    return ids


def find_open_issue(cb, repo, title):
    """Number of an open issue with exactly this title, else None."""
    q = urllib.parse.quote(title)
    for page in range(1, 4):
        batch = cb.call(
            "GET",
            f"/api/v1/repos/{repo}/issues?state=open&type=issues&q={q}&limit=50&page={page}",
        )
        for found in batch:
            if found.get("title") == title:
                return found["number"]
        if len(batch) < 50:
            break
    return None


def main():
    env = os.environ
    token = env.get("FORGEJO_TOKEN", "")
    if not token:
        print("no FORGEJO_TOKEN (Secret forgejo-b4mad missing): not opening an issue")
        return 0
    ns, run, repo = env["PIPELINERUN_NAMESPACE"], env["PIPELINERUN_NAME"], env["REPO"]
    k8s = k8s_client()
    failures = failed_steps(k8s, ns, run)
    if not failures:
        print("no failed TaskRun (cancelled run?): not opening an issue")
        return 0
    pr = k8s.call("GET", f"/apis/tekton.dev/v1/namespaces/{ns}/pipelineruns/{run}")
    pipeline = (
        pr["metadata"]
        .get("labels", {})
        .get("pipelinesascode.tekton.dev/original-prname", run)
    )

    cb = Http(
        f"{FORGE}",
        {"Authorization": f"token {token}", "User-Agent": "op1st-emea-b4mad-ci-report-failure"},
    )
    names = [n.strip() for n in env.get("LABELS", "").split(",") if n.strip()]
    body = redact(build_issue(env, pipeline, failures), (token,))
    # No SHA in the title: the same pipeline failing again on the same
    # branch is the same problem, so it lands on the open issue as a
    # comment instead of a second issue.
    title = f"CI failed: {pipeline} on {env.get('SOURCE_BRANCH') or 'unknown'}"
    number = find_open_issue(cb, repo, title)
    if number:
        cb.call(
            "POST",
            f"/api/v1/repos/{repo}/issues/{number}/comments",
            {"body": "## Failed again\n\n" + body},
        )
        print(f"failure recurred, commented on existing issue #{number}")
    else:
        issue = {
            "title": title,
            "body": body,
            "labels": label_ids(cb, repo, names),
            "assignees": [env["ASSIGNEE"]] if env.get("ASSIGNEE") else [],
        }
        try:
            created = cb.call("POST", f"/api/v1/repos/{repo}/issues", issue)
        except urllib.error.HTTPError as exc:
            if not issue["assignees"]:
                raise
            # Most likely the assignee cannot be assigned in this repo. An
            # unassigned issue beats no issue.
            print(
                f"warning: assignment to {env['ASSIGNEE']} failed ({exc.code}), retrying without"
            )
            issue["assignees"] = []
            issue["body"] += (
                f"\n\n⚠️ Assignment to `{env['ASSIGNEE']}` failed ({exc.code}). Please assign by hand."
            )
            created = cb.call("POST", f"/api/v1/repos/{repo}/issues", issue)
        number = created["number"]
        print(f"opened {created.get('html_url', number)}")

    for task, _reason, _message, bad, pod in failures:
        for container, step, code in bad:
            log = redact(step_log(k8s, ns, pod, container), (token,))
            for text, full in log_comments(task, step, code, log):
                comment = cb.call(
                    "POST",
                    f"/api/v1/repos/{repo}/issues/{number}/comments",
                    {"body": text},
                )
                if full is not None:
                    attach(cb, repo, comment["id"], f"{task}-{step}.log", full)
    return 0


if __name__ == "__main__":
    sys.exit(main())
