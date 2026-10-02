---
name: headroom
description: Keeps the host machine responsive by scaling how much load the agent puts on it. Use before spawning subagents or parallel work, and before running builds, test suites, dependency installs, dev or watch servers, headless browsers, or docker.
---

# Headroom

Leave the machine **headroom**: the CPU and RAM the host needs to stay responsive while you work. A small VPS needs a lot of it; a strong laptop needs little. Work is allowed to be slow; it must never choke the host or get the session OOM-killed.

## 1. Pick the level, once per session

First match wins:

1. `HEADROOM_LEVEL` environment variable.
2. A `headroom: <low|medium|high>` line in `CLAUDE.md` / `AGENTS.md`.
3. Run `scripts/detect.sh` from this skill's folder. It reads CPU, RAM and current load and prints the level with its reason.

State the level and reason to the user in one line, then keep it for the rest of the session.

## 2. Work within the level

|                                   | **low**                                                  | **medium**                    | **high**  |
| --------------------------------- | -------------------------------------------------------- | ----------------------------- | --------- |
| Subagents                         | none; one at a time when the user asks for one           | up to 2 at once               | as needed |
| Heavy commands at once            | 1, prefixed with `nice -n 19`                            | 2                             | as needed |
| Tool workers                      | 1                                                        | half the cores                | default   |
| Tests                             | the one file or module you changed                       | the changed package           | as needed |
| Build / typecheck                 | once, at the end                                         | after each logical unit       | as needed |
| Browser, docker, dev server       | only when it *is* the task                               | one at a time                 | as needed |
| Worktrees / fresh clones          | the existing checkout                                    | the existing checkout         | as needed |

A **heavy command** is anything that compiles, bundles, installs, runs a test suite, or starts a browser, container or server. Per-tool flags for setting workers to 1 or half the cores are in [`STACKS.md`](STACKS.md); read it before the first heavy command at low or medium.

On every level:

- Reuse what is installed: run a dependency install only when the lockfile or manifest changed, using the stack's frozen/offline mode.
- Read narrowly: `grep`, `head`, `tail`, and ranged reads for large files and logs.
- At low and medium, keep a `PROGRESS.md` in the working directory, updated after each finished step (done, next, open questions), so compaction or a restart resumes without redoing work. Keep it out of commits and delete it when the task is finished.

## 3. Finish clean

The turn is done when every process you started (watchers, dev servers, browsers, containers, background jobs) is stopped and `PROGRESS.md`, if the level requires one, matches reality.
