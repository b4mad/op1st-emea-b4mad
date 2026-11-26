"""Tests for scripts/ci-report-failure.py and the .tekton wiring guard.

Run: python3 -m unittest discover -s tests   (stdlib + PyYAML for the guard test)
"""

import importlib.util
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO = Path(__file__).resolve().parent.parent


def load(name, file):
    spec = importlib.util.spec_from_file_location(name, REPO / "scripts" / file)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


mod = load("ci_report_failure", "ci-report-failure.py")
guard = load("check_tekton_report_failure", "check-tekton-report-failure.py")

# Assembled at runtime so gitleaks does not flag the fixture as a real key.
KEY = "OPENSSH " + "PRIVATE"


class FakeForge:
    def __init__(self, open_issues=()):
        self.open_issues = list(open_issues)
        self.posts = []

    def call(self, method, path, body=None, **_kw):
        if method == "GET" and "/labels" in path:
            return [{"name": "bug", "id": 1}, {"name": "intake", "id": 2}]
        if method == "GET" and "/issues?" in path:
            return self.open_issues
        self.posts.append((path, body))
        if path.endswith("/issues"):
            return {"number": 7, "html_url": "u"}
        return {"id": 99}


class FakeK8s:
    def call(self, method, path, raw=False, **_kw):
        if raw:
            return "FAILED test_x\npassword=hunter2"
        return {
            "metadata": {
                "labels": {"pipelinesascode.tekton.dev/original-prname": "code-scans"}
            }
        }


FAILURES = [
    ("gitleaks", "Failed", "step gitleaks exited 1", [("step-gitleaks", "gitleaks", 1)], "pod-1")
]
ENV = {
    "REVISION": "a" * 40,
    "REPO": "operate-first/op1st-emea-b4mad",
    "PIPELINERUN_NAME": "code-scans-x",
    "PIPELINERUN_NAMESPACE": "op1st-pipelines",
    "SOURCE_BRANCH": "main",
    "EVENT_TYPE": "push",
    "ASSIGNEE": "b4mad-castra",
    "LABELS": "bug,intake,nope",
    "FORGEJO_TOKEN": "tok",
}


class Redaction(unittest.TestCase):
    def test_scrubs_secrets_and_ansi(self):
        text = (
            "\x1b[31mred\x1b[0m\n"
            "Authorization: Bearer abc123\n"
            "export API_TOKEN=hunter2\n"
            "git clone https://bot:s3cret@git.example/x\n"
            f"-----BEGIN {KEY} KEY-----\nAAAA\n-----END {KEY} KEY-----\n"
            "literal-tok-999 appears"
        )
        out = mod.redact(text, ("literal-tok-999",))
        for leaked in ("abc123", "hunter2", "s3cret", "AAAA", "literal-tok-999", "\x1b"):
            self.assertNotIn(leaked, out)
        self.assertIn("red", out)

    def test_fence_outgrows_backticks(self):
        self.assertEqual(mod.fence("plain"), "```")
        self.assertEqual(mod.fence("a ```` b"), "`" * 5)

    def test_short_inline_long_attached(self):
        ((body, full),) = mod.log_comments("t", "s", 1, "short")
        self.assertIsNone(full)
        self.assertIn("short", body)
        big = "x" * (mod.INLINE_LIMIT + 10)
        ((body, full),) = mod.log_comments("t", "s", 1, big)
        self.assertEqual(full, big)
        self.assertIn("attached", body)
        self.assertLess(len(body), mod.INLINE_LIMIT + 500)


class Main(unittest.TestCase):
    def run_main(self, cb, env=ENV):
        with (
            mock.patch.dict(os.environ, env, clear=True),
            mock.patch.object(mod, "k8s_client", lambda: FakeK8s()),
            mock.patch.object(mod, "failed_steps", lambda *_a: FAILURES),
            mock.patch.object(mod, "Http", lambda *_a, **_k: cb),
        ):
            return mod.main()

    def test_first_failure_opens_labelled_assigned_issue_then_comments_log(self):
        cb = FakeForge()
        self.assertEqual(self.run_main(cb), 0)
        (path, issue), (cpath, comment) = cb.posts
        self.assertTrue(path.endswith("/issues"))
        self.assertEqual(issue["labels"], [1, 2])  # unknown label skipped
        self.assertEqual(issue["assignees"], ["b4mad-castra"])
        self.assertEqual(issue["title"], "CI failed: code-scans on main")
        self.assertTrue(cpath.endswith("/issues/7/comments"))
        self.assertIn("FAILED test_x", comment["body"])
        self.assertNotIn("hunter2", comment["body"])

    def test_recurring_failure_comments_on_open_issue(self):
        cb = FakeForge(open_issues=[{"number": 5, "title": "CI failed: code-scans on main"}])
        self.run_main(cb)
        self.assertFalse(any(p.endswith("/issues") for p, _ in cb.posts))
        self.assertTrue(all("/issues/5/comments" in p for p, _ in cb.posts))
        self.assertTrue(cb.posts[0][1]["body"].startswith("## Failed again"))

    def test_no_token_is_a_noop(self):
        cb = FakeForge()
        env = {k: v for k, v in ENV.items() if k != "FORGEJO_TOKEN"}
        self.assertEqual(self.run_main(cb, env), 0)
        self.assertEqual(cb.posts, [])


class Guard(unittest.TestCase):
    def test_every_pipeline_reports_failures(self):
        files = sorted((REPO / ".tekton").glob("*.yaml"))
        self.assertTrue(files)
        for f in files:
            with self.subTest(f=f.name):
                self.assertEqual(guard.problems(f), [])

    def test_guard_flags_pipeline_without_finally(self):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "p.yaml"
            f.write_text(
                "kind: PipelineRun\nmetadata: {name: x}\nspec:\n  pipelineSpec:\n    tasks: []\n"
            )
            self.assertTrue(guard.problems(f))


if __name__ == "__main__":
    unittest.main()
