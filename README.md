# superset-claude-telegram

Auto-start Telegram-connected [Claude Code](https://docs.anthropic.com/en/docs/claude-code) sessions in [Superset](https://docs.superset.sh) worktrees — each worktree gets its own Telegram topic.

Control Claude Code remotely via Telegram from your phone. Every worktree creates a dedicated topic in your bot's group chat, so multiple sessions run simultaneously without conflicts.

Uses [claude-telegram-enhanced](https://github.com/vladzima/claude-telegram-enhanced) for topic routing and response streaming.

## Prerequisites

- [Superset](https://superset.sh) installed
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A Telegram bot set up in a group chat with topics enabled

## Telegram setup (one-time)

Before using this project, you need a Telegram bot in a group chat with topics enabled. This only needs to be done once.

### 1. Create a bot

1. Open [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot`, pick a name and username
3. Copy the token (`123456789:AAHfiqksKZ8...`)

### 2. Enable bot features in BotFather

1. Send `/mybots` → select your bot → **Bot Settings**
2. Enable **Threaded Mode** (required for topics)
3. Turn **off** **Group Privacy** (so the bot receives all messages in the group, not just commands)

### 3. Create a group chat with topics

1. Create a new Telegram group
2. Go to group settings → enable **Topics**
3. Add your bot to the group
4. **Make the bot an admin** (it needs admin rights to create topics, react to messages, and manage topics)

### 4. Get the group's chat ID

Add [@userinfobot](https://t.me/userinfobot) to the group — it will print the chat ID (a negative number like `-1001234567890`). Remove it after.

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

Optionally enable **Auto-run > When creating a workspace** to launch Claude Telegram automatically on every new worktree. This is safe — each worktree gets its own topic, so multiple sessions won't conflict.

### 3. Run the preset on a workspace

Create or switch to a workspace, then launch the **Claude Telegram** preset from the terminal preset bar.

On first run, the script will:
1. Register the [enhanced Telegram plugin](https://github.com/vladzima/claude-telegram-enhanced) marketplace and install the plugin
2. Prompt for your bot token (stored globally — only asked once)
3. Prompt for your group chat ID (only asked once)
4. Create a Telegram topic named after the workspace
5. Launch Claude Code with Telegram channels and autonomous permissions

> **Note:** On first launch you'll see a "Loading development channels" safety prompt — select "I am using this for local development" and press Enter. This only appears once.

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

## Workspace teardown

When a workspace is terminated in Superset, the teardown script (`teardown.sh`) automatically **closes (archives)** the Telegram topic associated with that workspace. The topic and its messages are preserved in Telegram — they're just archived, not deleted.

This is configured in `.superset/config.json`:

```json
{
  "teardown": ["./teardown.sh"]
}
```

The teardown works by matching the workspace name to persisted topic metadata in `~/.claude/channels/telegram/daemon/topics/`. If no matching topic is found (e.g., the workspace never had Telegram set up), it silently exits.

## How it works

```
Superset worktree created
  └── Terminal Preset: ./setup.sh
        ├── Installs enhanced Telegram plugin (idempotent)
        ├── Neutralizes official Telegram plugin (prevents conflicts)
        ├── Checks bot token + chat ID (prompts once, saves globally)
        ├── Sets TELEGRAM_TOPIC_NAME = workspace display name
        └── Launches claude with topic routing
              └── Plugin starts shared polling daemon (if not running)
                    └── Creates topic in your Telegram group
                          ├── Sends "Claude Code session ready" welcome message
                          └── All messages scoped to that topic

Superset worktree terminated
  └── .superset/config.json teardown: ./teardown.sh
        ├── Finds topic metadata by workspace name
        └── Calls closeForumTopic via Telegram API
```

The bot token and chat ID persist at `~/.claude/channels/telegram/.env` — shared across all worktrees and projects.

A single polling daemon handles Telegram updates for all sessions. Each worktree's plugin instance watches its own topic inbox — no conflicts, no stolen updates.

Topic name is derived from: Superset workspace name → git branch → directory name (first available).

## Adding to an existing project

Copy `setup.sh`, `teardown.sh`, and `.superset/config.json` to your project root:

```bash
cp /path/to/superset-claude-telegram/setup.sh .
cp /path/to/superset-claude-telegram/teardown.sh .
cp -r /path/to/superset-claude-telegram/.superset .
chmod +x setup.sh teardown.sh
```

## Security notes

- `--dangerously-skip-permissions` is required because permission prompts can't be answered via Telegram. Only use this in trusted project directories.
- `--dangerously-load-development-channels` is needed because the enhanced plugin is not yet on Claude's official channel allowlist.
- After pairing, switch to allowlist mode to prevent unauthorized users from pairing with your bot.
- The bot token is stored locally at `~/.claude/channels/telegram/.env` and never committed to any repo.
