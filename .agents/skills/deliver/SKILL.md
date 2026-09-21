---
name: deliver
description: Deliver a bead end-to-end — plan it into child beads, implement each one in its own herdr tab with a separate Claude session, run the repo's test gate, and open one clean PR. Wraps /work-on at the start and /done-with at the end.
argument-hint: "<bead-id> [--parallel] [--tasks-only] [--team]"
license: GPL-3.0-or-later
author: goern
version: 0.2.0
compatibility: Requires the `bd`, `wt`, `herdr` and `claude` CLIs, plus the `work-on` and `done-with` skills; a commit skill and a forge CLI or MCP server are used when the repo provides them
---

Delivery driver for one bead: `/work-on` → plan → child beads → one herdr tab
per task → the repo's test gate → PR → `/done-with`.

You are the **lead**. You do not write feature code yourself; each child task is
implemented by a separate Claude session in its own herdr tab. You plan, brief,
watch, verify, and ship.

## Model

Run this skill's own steps on Sonnet. Skills can't pin a model via frontmatter
(that's a Command-only field) — this is a best-effort instruction to the
invoking agent. The spawned per-task sessions *are* pinned, explicitly, on their
command line (`claude --model sonnet`).

## Nothing here is repo-specific

Like the rest of this repo, `/deliver` hardcodes no repository, forge, package
manager or test runner. Three things are **discovered per repo**, in Step 2, and
carried as variables:

| Variable | What it is | Discovered from |
| --- | --- | --- |
| `$GATE` | the one command that must exit 0 before a PR | `CLAUDE.md` / `AGENTS.md`, then `package.json` scripts, `Makefile`, `justfile`, CI config |
| `$TEST_HOME` | where a test for a given change belongs | the existing test layout |
| `$SHELL_CMD` | optional command to enter the dev environment in a fresh pane | `CLAUDE.md`, devcontainer/toolbox/nix config |

If you cannot find `$GATE`, **ask** — do not invent a test command. A gate you
made up is worse than no gate: it goes green on a repo it never ran.

## Arguments

`$ARGUMENTS`. Grammar: `<bead-id> [--parallel] [--tasks-only] [--team]`.

- **bead-id** — required, the bead to deliver.
- **`--parallel`** — implement independent tasks concurrently, each in its own
  worktree. Off by default; see Step 4's warning.
- **`--tasks-only`** — stop after Step 3 (plan + child beads created), spawn no
  implementer session.
- **`--team`** — implement each task with `team:dev-loop` (in-session
  implementer + verifier) instead of a herdr-tab Claude session. Requires that
  skill to be installed; see below.

## Relationship to `team:dev-loop`

They solve different halves and are deliberately **not** merged:

| | `team:dev-loop` | `/deliver` |
| --- | --- | --- |
| Unit of work | one scoped slice you already framed | one bead, from "read it" to "PR ready to merge" |
| Workers | in-session subagents (`Agent`), shared process | out-of-process `claude` sessions in herdr tabs |
| Owns | the impl↔verify loop until a command exits 0 | bead planning, worktree, branch, tests, PR, cleanup |
| Ends with | verifier PASS | a pushed PR and a freed tab |

Folding the bead/worktree/PR/herdr machinery into `team:dev-loop` would make a
generic, cross-project loop skill depend on `bd`, `wt` and `herdr` — it would
stop being reusable. The fold goes the *other* way: `/deliver` borrows
dev-loop's hard-won worker discipline (Step 4) and, with `--team`, calls it as
the per-task engine:

```
Skill(skill: "team:dev-loop", args: "<child bead title>. Files: <paths>. Verifier: <$GATE or its narrow form>")
```

Use `--team` when the task is a tight code+test loop in this repo and you want
the verifier inside the loop. Use the default tab when you want a real,
separately budgeted session per task that the user can watch and steer.

## Step 0 — no argument means stop

If `$ARGUMENTS` has no bead id, print exactly this help text and **do nothing
else**. No tools, no worktree, no tabs.

```
/deliver <bead-id> [--parallel] [--tasks-only] [--team]

Delivers one bead end-to-end:
  1. /work-on <bead-id>       — tab + session named, worktree created, bead loaded
  2. plan it                  — review the bead, find the repo's test gate, write a plan
  3. bd create --parent=...   — one child bead per task, dependency-ordered
  4. herdr tab per task       — one claude --model sonnet session per child bead
  5. verify                   — run the repo's full gate yourself
  6. one clean PR             — commit, push, open the PR
  7. /done-with               — worktree removed, tab and session freed

  --parallel     independent tasks get their own worktree (see the warning)
  --tasks-only   stop after step 3
  --team         use team:dev-loop per task instead of a herdr tab

Every spawned session is exited and its tab closed when its task ends.

Example: /deliver acme-4f2k
Find work with: bd ready
```

## Step 1 — start the work session

```
Skill(skill: "work-on", args: "<bead-id>")
```

`work-on` owns bead validation, the tab and session rename, and the worktree. If
it stops (bogus id, worktree failure), **stop here too** — there is nothing to
deliver into.

Record for later steps:

- `BEAD` — the bead id, also the branch name and the tab label
- `WORKTREE` — the worktree path this session was re-rooted into
- `PANE` — `$HERDR_PANE_ID`, the pane this session runs in. Never resolve it
  from `herdr api snapshot`'s `focused_tab_id` or from "the focused pane in
  `herdr pane list`" — the user switches tabs while you work, and you would
  drive a bystander's pane.
- `WORKSPACE` / `TAB` — `herdr pane get "$PANE"` → `.workspace_id`, `.tab_id`

If `$HERDR_PANE_ID` is unset this session is not inside herdr: say so and go to
the fallback in Step 4.

## Step 2 — review the bead, find the gate, plan

Read the bead body from Step 1 plus whatever it points at (files, ADRs, design
docs). Then answer, in the report, before planning:

- what is actually being asked, in one sentence
- what the acceptance evidence is — the command that fails today and passes
  after, and which test files carry the proof
- what is *not* in scope

⚠️ If the bead is vague, contradicts an active design decision, or is really
several unrelated changes, say so and **ask before creating a single child
bead**. A bad plan multiplied across N sessions is N times the cleanup.

### Find the harness — do not invent one

Resolve `$GATE`, `$TEST_HOME` and `$SHELL_CMD` (see *Nothing here is
repo-specific*). In order of authority:

1. `CLAUDE.md` / `AGENTS.md` in the repo — if they name the gate, that is the
   gate, full stop.
2. `package.json` scripts, `Makefile`, `justfile`, `Cargo.toml`, `pyproject.toml`.
3. The CI workflow — whatever the pipeline runs on a PR is the real bar.

A typical `$GATE` is a conjunction, cheapest check first, e.g.
`npm run lint && npm run typecheck && npm test`, or `make check`, or
`cargo clippy -- -D warnings && cargo test`. Record the **narrow** form too
(one package / one workspace) — implementers iterate on that and the lead runs
the whole thing.

State `$GATE` verbatim in the report. Everything downstream quotes it; nobody
downstream is allowed to improvise a different one.

### Write the plan

An ordered list of tasks, each a reviewable unit of work with its own
verification. Aim for **3–7 tasks**; more than that usually means the bead
should have been split.

Every plan includes its tests as tasks, not as an afterthought. Each task names
the **command** that proves it and the **file** the new test goes in, under
`$TEST_HOME`. A task with no way to fail is not a task.

## Step 3 — create the child beads

One child per task, rooted under the parent:

```bash
bd create --title="<task title>" \
          --description="<what, why, the command and test file that prove it>" \
          --type=task --priority=2 --parent="$BEAD"
```

Then encode the order. Sequential is the default — task N+1 depends on task N:

```bash
bd dep add <child-N+1> --blocked-by <child-N>
```

Only omit a dependency when the two tasks genuinely touch disjoint files; those
are the tasks `--parallel` may run concurrently.

Claim the parent — **after** the plan is agreed, never before:

```bash
bd update "$BEAD" --claim
```

Report the plan as a numbered list with the child bead ids. **With
`--tasks-only`, stop here** — the tab stays labelled with the bead, because the
work is not done.

## Step 4 — implement each task in its own herdr tab

Needs `$HERDR_PANE_ID` from Step 1. Without it, fall back to implementing the
tasks in this session, one at a time, still following the briefs below — and say
in the report that you did.

### Where the work happens

**Default (sequential):** every task session runs in `$WORKTREE` — the one
`/work-on` created. One branch, one history, one PR. Run one task at a time and
wait for it to finish before starting the next.

⚠️ **`--parallel` is not free.** Two Claude sessions editing the same worktree
clobber each other, so `--parallel` gives each task its own worktree via
`wt switch --create "$BEAD-<n>" --no-cd --format=json`, and you then merge each
back into `$BEAD` with `wt merge --no-squash --no-commit`. That merge dance
costs more than it saves unless the tasks are genuinely disjoint and
long-running. When in doubt, don't pass it.

### Per task

Claim the child before spawning its session — the tracker should show which
task is actually being worked, the same reason the parent gets claimed in Step 3:

```bash
bd update "$CHILD_ID" --claim
```

```bash
TAB_JSON=$(herdr tab create --workspace "$WORKSPACE" --cwd "$TASK_CWD" \
  --label "$CHILD_ID" --no-focus)
TAB_ID=$(printf '%s' "$TAB_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["tab_id"])')
TAB_PANE=$(printf '%s' "$TAB_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["root_pane"]["pane_id"])')
```

Keep **both** ids: the pane is what you drive, the tab is what you close in the
teardown.

If `$SHELL_CMD` is set, enter the dev environment first and wait for a prompt.
`--match` and `--regex` are alternatives, not a flag plus a modifier — pass one:

```bash
herdr pane run "$TAB_PANE" "$SHELL_CMD"
herdr pane wait-output "$TAB_PANE" --regex '\$ $' --timeout 60000
```

Then start the implementer and wait for herdr to *recognise* it, which is not
the same as its prompt appearing — `wait-output` on `>` races the banner and
usually times out even though the agent is up. Poll the agent instead:

```bash
herdr pane run "$TAB_PANE" "claude --model sonnet"
herdr agent wait "$TAB_PANE" --until idle --timeout 60000
```

Send the brief with `herdr agent prompt`, **not** `herdr pane run` — it submits
to the agent as one prompt, so a long brief cannot arrive half-written, and the
same call waits for the turn to settle:

```bash
herdr agent prompt "$TAB_PANE" "<brief>" --wait --until done --timeout 3500000
```

⚠️ That wait can outlive the `Bash` tool's 10-minute ceiling, and a task that
finishes in four minutes still beats a lead that timed out at ten. Run it with
`run_in_background: true` and act on the completion notification.

The brief must contain, in this order:

1. `bd show <child-id>` — tell it to read its own bead first
2. the worktree path and the branch it is on, and that it must **not** switch
   branches, merge, push, or open a PR — the lead does that
3. the change to make, in the bead's own words
4. the tests it must add or extend, named by path, under `$TEST_HOME`
5. the command that proves it green. Narrow while iterating is fine, but the
   task is not done until the **full** `$GATE` is green. Quote `$GATE`
   verbatim; never let the implementer compose its own.
6. **verbatim discipline clauses** (these are dev-loop's, and each one exists
   because it has already failed in practice):

   > Never end a turn silent. After every 2 sub-tasks, print one line
   > `progress: <what> done, on <next>`. Silence is the only failure signal
   > the lead has.

   > If the harness reports `0 passed`, `no tests ran`, or `no test files
   > matched`, that is a FAIL, not a pass. This task adds tests; zero matches
   > means they were never written or the filter is wrong. Read the per-suite
   > output, not just the exit code.

   > For each sub-task, produce evidence — a test name, a file path, or a diff
   > hunk. "Done" without evidence is not done.

   > Stay in: `<paths>`. Do not touch: `<paths>`. Do not fix unrelated
   > production code — surface it, do not silently fix.

7. `bd close <child-id>` when the tests pass, then **exit the session** — do not
   idle, do not pick up the next task

`agent prompt --wait` already returned when the turn settled, so read the
result:

```bash
herdr pane read "$TAB_PANE" --source recent --lines 120
```

If you ever need to wait separately — you sent the brief without `--wait`, or
you are re-checking a tab — that is `herdr agent wait`, which takes `--until`,
not `--status`:

```bash
herdr agent wait "$TAB_PANE" --until done --timeout 3500000
```

If it reports blocked, or the wait times out, **do not start the next task** —
read the pane, decide, and either brief it again in the same tab or take the
task over yourself. A silently skipped task becomes a broken PR.

### End the session when the task is done

⚠️ A finished Claude session left sitting at its prompt keeps a pane, a dev
container and a budget alive, and the next tab lands on a machine with N stale
agents. Tear it down explicitly — every task, every time, **including the
failure paths**:

```bash
herdr pane read "$TAB_PANE" --source recent --lines 200   # scrollback dies with the tab
herdr pane send-keys "$TAB_PANE" Escape                   # see the warning below
herdr pane run "$TAB_PANE" "/exit"
herdr pane wait-output "$TAB_PANE" --regex '\$ $' --timeout 30000
[ -n "$SHELL_CMD" ] && herdr pane run "$TAB_PANE" "exit"
herdr tab close "$TAB_ID"
```

⚠️ Send `Escape` first. A finished session can be left with text sitting in its
input box — a suggestion it drafted, or something a passing human typed — and
`pane run` appends to whatever is already there, so `/exit` becomes
`commit this/exit` and submits as a prompt. Clearing costs one call; not
clearing hands an idle agent an instruction nobody wrote.

Keep what you need from that last read in your own report before closing.

If the task **failed** or was taken over, still end the session — but record
what it got to in the child bead first (`bd update <child-id> --notes=...`), so
the context survives the teardown.

At the end of Step 4, `herdr tab list --workspace "$WORKSPACE"` must show no
leftover task tabs. If one is still there, close it.

## Step 5 — verify the whole thing yourself

Do not trust the per-task green, and do not assemble your own command list — run
`$GATE`, whole, from `$WORKTREE`, in a sibling pane:

```bash
GATE_PANE=$(herdr pane split "$PANE" --direction down --no-focus \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["pane"]["pane_id"])')
herdr pane run "$GATE_PANE" "$GATE"
herdr pane wait-output "$GATE_PANE" --regex 'error|failed|✗ |\$ $' --timeout 1800000
herdr pane read "$GATE_PANE" --source recent-unwrapped --lines 200
```

Read the actual output — quote the shortest decisive line if it is red. A red
gate is a stop, not a footnote: fix it or re-brief the task that broke it, then
re-run the **whole** gate before Step 6. **Never narrow the gate to make it
pass.**

## Step 6 — one clean PR

Check the diff before you write a word of the PR body:

```bash
git diff main --stat
```

"Clean" means only the files this bead needed: no bead-tracker exports, no
unrelated formatting churn, no stray build output. Say what is in it.

Commit through the repo's own commit skill if it has one (`ds:commit` here per
`CLAUDE.md`) rather than hand-crafting `git commit`. Honour the repo's message
conventions — in this repo, emoji goes **after** the first `:` in the subject.

Push the branch, then open the PR against the default branch with whatever the
repo already uses, in this order of preference:

1. a forge skill or MCP server that is configured (`forgejo`, `ds:pr`, a
   `mcp__*__create_pull_request` tool)
2. the forge CLI (`gh pr create`, `tea pr create`, `glab mr create`)

Never `curl` the forge API: the `origin` URL and the ambient environment carry
tokens, and a hand-rolled request leaks them into scrollback and logs.

The PR body is normal English prose and states:

- what changed and why, linking the bead id and any design doc
- the tests that prove it — the commands run, and the new test files by path
- anything deliberately left out

## Step 7 — close out

```bash
bd close <child-1> <child-2> ...   # any still open
bd close "$BEAD"
```

Then:

```
Skill(skill: "done-with", args: "<bead-id>")
```

`done-with` refuses while the tree is dirty, or while the branch is neither
merged nor carrying an open PR — that refusal is the safety net, so do not work
around it. It removes the worktree and renames the tab and the session back to
`free`. The session rename lands on the user's next message, not immediately;
say so rather than claiming both are already done.

## Step 8 — end this session too

The lead session is done when the PR is open and `/done-with` has run:

- all task tabs closed (Step 4)
- gate pane closed: `herdr pane close "$GATE_PANE"`
- `--team` runs only: `SendMessage` each teammate `{type:"shutdown_request"}`
  and wait for the approvals — teammates never originate their own shutdown

Then report and stop. Do not keep the session open "in case" — the bead is
closed and the PR is the handoff.

## Step 9 — report

One block:

- bead id and title, child beads created and their state
- PR number and URL
- `$GATE` verbatim, and its result — pass/fail, with the failing names if any
- anything left open, as a bead id
