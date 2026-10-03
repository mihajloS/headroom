# headroom

An agent skill that keeps the machine your coding agent runs on responsive. It detects how strong the host is, picks a load level, and has the agent scale subagents, parallel commands, test scope and build frequency to match.

Made for long-running, unhurried sessions on a small VPS (e.g. a 1 GB droplet you drive from your phone), while staying out of the way on a strong laptop.

## Why

The model runs on the provider's servers, not your box. What loads your machine is what the agent *starts*: test suites, builds, dependency installs, dev servers, headless browsers, containers. Several subagents each running those at once is how a small droplet swaps itself to death or gets the session OOM-killed. `headroom` makes that load proportional to the machine.

It does **not** try to save tokens. For that, see the complementary [caveman](https://github.com/JuliusBrussee/caveman), [savethetokens](https://github.com/Redclawww/savethetokens) or [rescue-tokens](https://github.com/valorisa/Claude-Skills).

## Levels

| Level | Picked when | Behaviour |
| --- | --- | --- |
| `low` | ≤ 2 CPUs or ≤ 4 GB RAM | no subagents unless asked, one heavy command at a time under `nice`, single-worker tools, targeted tests, one build at the end, `PROGRESS.md` for resumability |
| `medium` | ≤ 8 CPUs or ≤ 16 GB RAM | up to 2 subagents / heavy commands, half the cores for tool workers |
| `high` | anything bigger | agent's normal behaviour, still cleans up background processes |

A busy machine (load ≥ CPU count, or under 15% RAM available) drops one level. Check what your machine gets:

```bash
./scripts/detect.sh
```

Override per machine with an environment variable or a line in `CLAUDE.md` / `AGENTS.md`:

```bash
export HEADROOM_LEVEL=low
```

## Install

### Claude Code

```bash
git clone --depth 1 https://github.com/mihajloS/headroom ~/.claude/skills/headroom
```

Then add one line to `~/.claude/CLAUDE.md` so the agent reaches for it at the right moment without you thinking about it:

```markdown
Before the first build, test run, dependency install, server, browser, docker command or subagent, invoke the `headroom` skill.
```

Recommended: also put the level into the agent's context at session start, so it holds even before the skill is invoked, with a `SessionStart` hook in `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      { "hooks": [{ "type": "command", "command": "~/.claude/skills/headroom/scripts/detect.sh" }] }
    ]
  }
}
```

### Other agents (Codex, Cursor, …)

Agents that support the [Agent Skills](https://agentskills.io) format load `SKILL.md` from their skills folder. Agents that only read `AGENTS.md` can be pointed at it:

```markdown
Before spawning subagents or running builds, tests, installs, servers, browsers or docker, follow /path/to/headroom/SKILL.md.
```

## Small-droplet tip

Give a 1–2 GB droplet a swap file so a spike slows things down instead of killing the session:

```bash
sudo fallocate -l 2G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

## License

MIT
