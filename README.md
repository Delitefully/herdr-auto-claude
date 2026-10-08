<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/logo-lockup-dark.png">
  <img src="assets/logo-lockup.png" alt="auto-claude" width="516">
</picture>

A [herdr](https://herdr.dev) plugin that starts Claude Code in the first pane of
every new space. Tabs and splits you open in that space afterwards stay plain
shells.

## Install

    herdr plugin install Delitefully/herdr-auto-claude

That is the whole setup. The next space you open comes up with Claude already
running in it.

To pause it: `herdr plugin disable herdr-auto-claude`.
To remove it: `herdr plugin uninstall herdr-auto-claude`.

## What starts Claude

| | Claude starts |
|---|---|
| a new space | yes, in its first pane |
| a new herdr worktree | yes, since creating one opens a space |
| a new tab or split | no |
| a server restart | no new one, see below |
| a pane already running Claude, moved into a new space | no, it is left alone |
| an idle shell pane, moved into a new space | yes |

## How it works

It is one event hook and a short shell script. herdr fires `workspace.created`
once for each new space and never for tabs or panes, so hooking that event is
the whole "first pane only" rule. There is nothing to track and no state kept.

The script starts Claude with `herdr agent start --kind claude` rather than by
typing `claude` into the shell. `agent start` returns only once herdr has
detected Claude and it is ready for input, and it refuses a pane that is not
sitting at an idle shell prompt. That refusal is why a pane moved into a new
space with Claude running in it does not get a second one.

It waits up to 60 seconds for Claude to become ready, twice herdr's default,
because a Claude Code with a long MCP server list can be slow to start. If
Claude comes up waiting on a prompt, such as the folder trust dialog, that is
left for you to answer.

Each Claude is registered as a herdr agent named after its space, such as
`claude-w1`, so `herdr agent prompt claude-w1 "..."` reaches it from a script
or another agent.

## After a server restart

Restoring a session does not fire `workspace.created`, so the plugin does not
touch restored spaces. herdr's own session restore brings Claude back instead,
with `claude --resume`, as long as the Claude Code integration is installed:

    herdr integration install claude

## Requirements

herdr 0.9.1 or newer, on macOS or Linux. Nothing else: the script is POSIX `sh`
and reads herdr's JSON with `grep`.

Failures are recorded in `herdr plugin log list --plugin herdr-auto-claude`.

## Spaces claimed by athena

If you run [athena](https://github.com/Delitefully/athena), a chief-of-staff Claude that starts its own workers with a brief, it marks each space it creates with a claim file in `~/.local/state/athena/claims/` (or `$ATHENA_STATE_DIR/claims/`). The plugin leaves claimed spaces alone. `sh test/claim.sh` checks this.
