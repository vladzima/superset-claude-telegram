# superset-claude-telegram

Auto-start Telegram-connected [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions in [Superset](https://docs.superset.sh) worktrees.

Control Claude Code remotely via Telegram — each worktree gets its own autonomous Claude session you can message from your phone.

## Prerequisites

- [Superset](https://superset.sh) installed
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A Telegram bot token from [@BotFather](https://t.me/BotFather)

## Setup

### 1. Clone this repo (or add to your existing project)

```bash
git clone https://github.com/vladzima/superset-claude-telegram.git
```

Open the project in Superset.

### 2. Create a Terminal Preset in Superset

Go to **Settings > Terminal > Add Preset** and configure:

| Field | Value |
|-------|-------|
| **Name** | `Claude Telegram` |
| **Command** | `./setup.sh` |
| **Default** | No (see note below) |

> **Why not default?** Only one worktree can run the Telegram bot at a time. Trigger it manually on the workspace you want to control via Telegram.

### 3. Run the preset on a workspace

Create or switch to a workspace, then launch the **Claude Telegram** preset from the terminal preset bar.

On first run, the script will:
1. Install the Claude Code Telegram plugin (idempotent)
2. Prompt you for your bot token (stored globally — only asked once)
3. Launch Claude Code with Telegram channels and autonomous permissions

### 4. Pair with your bot on Telegram

Once Claude starts, DM your bot on Telegram. It will reply with a **6-character pairing code**. Enter it in Claude:

```
/telegram:access pair <code>
```

After pairing, optionally lock access:

```
/telegram:access policy allowlist
```

## How it works

`setup.sh` does three things:

```bash
# 1. Install Telegram plugin (safe to re-run)
claude plugin install telegram@claude-plugins-official

# 2. Check/prompt for bot token → saves to ~/.claude/channels/telegram/.env
# (only prompts on first ever run)

# 3. Launch Claude with Telegram + autonomous mode
claude --dangerously-skip-permissions --channels plugin:telegram@claude-plugins-official
```

The bot token persists at `~/.claude/channels/telegram/.env` — shared across all worktrees and projects.

## Adding to an existing project

Copy `setup.sh` to your project root and create the Terminal Preset as described above. The `.superset/config.json` in this repo is optional — it just provides empty setup/teardown hooks as a reference.

## Security notes

- `--dangerously-skip-permissions` is required because permission prompts can't be answered via Telegram. Only use this in trusted project directories.
- After pairing, switch to allowlist mode (`/telegram:access policy allowlist`) to prevent unauthorized users from pairing with your bot.
- The bot token is stored locally at `~/.claude/channels/telegram/.env` and never committed to any repo.
