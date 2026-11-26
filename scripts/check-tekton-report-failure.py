#!/usr/bin/env python3
"""Fail if a .tekton PipelineRun lacks the report-failure `finally` block.

Wired into .pre-commit-config.yaml. Needs PyYAML (present in the pre-commit
hook environment via `additional_dependencies`). Usage: pass files, or none to
check every .tekton/*.yaml.
"""

import sys
from pathlib import Path

import yaml

TASK_FILE = ".tekton/tasks/report-failure.yaml"
WHEN = [{"input": "$(tasks.status)", "operator": "in", "values": ["Failed"]}]


def problems(path):
    try:
        doc = yaml.safe_load(Path(path).read_text())
    except yaml.YAMLError as exc:
        return [f"invalid YAML: {exc}"]
    if not isinstance(doc, dict) or doc.get("kind") != "PipelineRun":
        return []
    spec = doc.get("spec", {}).get("pipelineSpec", {})
    found = [t for t in spec.get("finally", []) if t.get("name") == "report-failure"]
    if len(found) != 1:
        return ["no `report-failure` task in pipelineSpec.finally"]
    out = []
    task = found[0]
    if task.get("when") != WHEN:
        out.append("report-failure must run only `when: $(tasks.status) in [Failed]`")
    if task.get("workspaces") != [{"name": "source", "workspace": "source"}]:
        out.append("report-failure must bind workspace source -> source")
    ann = doc.get("metadata", {}).get("annotations", {})
    if TASK_FILE not in ann.get("pipelinesascode.tekton.dev/task", ""):
        out.append(f"annotation pipelinesascode.tekton.dev/task must list {TASK_FILE}")
    return out


def main(argv):
    root = Path(__file__).resolve().parent.parent
    files = argv or sorted(str(p) for p in (root / ".tekton").glob("*.yaml"))
    bad = 0
    for f in files:
        for msg in problems(f):
            print(f"{f}: {msg}")
            bad = 1
    return bad


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
