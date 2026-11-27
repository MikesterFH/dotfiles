# agents

The dotfiles' own APM package. [APM](https://github.com/microsoft/apm)
deploys it into every agent harness: Claude Code, GitHub Copilot and opencode.
The global manifest `~/.apm/apm.yml` (from `home/dot_apm/apm.yml.tmpl`)
references this folder by absolute path. A `chezmoi apply` that changes either
one reruns `apm install -g` (see `docs/adr/0026-agent-config-via-apm.md`).

## Layout

```
agents/
  apm.yml                               package manifest
  .apm/skills/<name>/SKILL.md           skills (Agent Skills format)
  .apm/instructions/<name>.instructions.md  global instructions (applyTo)
  .apm/prompts/<name>.prompt.md         prompts / slash commands
  .apm/agents/<name>.agent.md           subagents
```

## Workflow

- **Add or change a skill**: edit it here, then `chezmoi apply`. Don't run
  `apm install -g <pkg>`: it writes to the deployed `~/.apm/apm.yml`, and the
  next apply puts the repo version back and APM removes the package again.
- **Third-party package or MCP server**: add it to
  `home/dot_apm/apm.yml.tmpl`, pinned to a tag or commit.
- **Trying something out locally**: install it natively in the harness under
  a name no package uses, e.g. `wip-foo`. APM leaves files it didn't deploy
  alone. To keep the experiment, move it here and delete the native copy.
  Otherwise the next install refuses with "conflicts with unmanaged file".
- **Don't edit what APM deployed**, neither in `~/.claude/skills` nor
  `~/.copilot` nor `~/.config/opencode`. Don't change APM-managed MCP servers
  in a harness UI (`/mcp`) either. APM then treats such an entry as foreign
  and the whole install fails. Fix: delete the entry and apply again.
