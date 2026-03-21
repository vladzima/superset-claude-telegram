# superset-claude-telegram

Auto-start Telegram-connected [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions in [Superset](https://docs.superset.sh) worktrees — each worktree gets its own Telegram topic.

Control Claude Code remotely via Telegram from your phone. Every worktree creates a dedicated topic in your bot's chat, so multiple sessions run simultaneously without conflicts.

Uses [claude-telegram-enhanced](https://github.com/vladzima/claude-telegram-enhanced) for topic routing and response streaming.

## Prerequisites

- [Superset](https://superset.sh) installed
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A Telegram bot token from [@BotFather](https://t.me/BotFather) with **Threaded Mode** enabled

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

> **Why not default?** You may not want every worktree to auto-connect. Trigger it manually on the workspaces you want to control via Telegram.

### 3. Run the preset on a workspace

Create or switch to a workspace, then launch the **Claude Telegram** preset from the terminal preset bar.

On first run, the script will:
1. Register the [enhanced Telegram plugin](https://github.com/vladzima/claude-telegram-enhanced) marketplace and install the plugin
2. Prompt for your bot token (stored globally — only asked once)
3. Prompt for your Telegram chat ID (get it from [@userinfobot](https://t.me/userinfobot) — only asked once)
4. Create a Telegram topic named after the worktree
5. Launch Claude Code with Telegram channels and autonomous permissions

### 4. Pair with your bot on Telegram

On first use, DM your bot on Telegram — it replies with a **6-character pairing code**. In Claude:

```
/telegram:access pair <code>
```

Then lock access:

```
/telegram:access policy allowlist
```

You only need to pair once. After that, every new worktree just creates a new topic and starts working.

## How it works

```
Superset worktree created
  └── Terminal Preset: ./setup.sh
        ├── Installs enhanced Telegram plugin (idempotent)
        ├── Checks bot token (prompts once, saves globally)
        ├── Checks chat ID (prompts once, saves globally)
        ├── Sets TELEGRAM_TOPIC_NAME = worktree name
        └── Launches claude --channels with topic routing
              └── Plugin auto-creates topic in your Telegram chat
                    └── All messages scoped to that topic
```

The bot token and chat ID persist at `~/.claude/channels/telegram/.env` — shared across all worktrees and projects.

Topic name is derived from `$SUPERSET_WORKSPACE_NAME` (set by Superset) or falls back to the directory name.

## Adding to an existing project

Copy `setup.sh` to your project root, make it executable, and create the Terminal Preset as described above.

```bash
cp /path/to/superset-claude-telegram/setup.sh .
chmod +x setup.sh
```

## Security notes

- `--dangerously-skip-permissions` is required because permission prompts can't be answered via Telegram. Only use this in trusted project directories.
- After pairing, switch to allowlist mode to prevent unauthorized users from pairing with your bot.
- The bot token is stored locally at `~/.claude/channels/telegram/.env` and never committed to any repo.
