#!/usr/bin/env bash
set -euo pipefail

TOKEN_FILE="$HOME/.claude/channels/telegram/.env"
TOKEN_VAR="TELEGRAM_BOT_TOKEN"

# 1. Install the Telegram plugin (idempotent — safe to re-run)
echo "Ensuring Telegram plugin is installed..."
claude plugin install telegram@claude-plugins-official 2>/dev/null || true

# 2. Ensure the bot token is configured
if [ -f "$TOKEN_FILE" ] && grep -q "^${TOKEN_VAR}=" "$TOKEN_FILE" 2>/dev/null; then
  echo "Telegram bot token already configured."
else
  echo ""
  echo "No Telegram bot token found."
  echo "Create a bot via @BotFather on Telegram, then paste the token below."
  echo ""
  printf "Bot token: "
  read -r TOKEN

  if [ -z "$TOKEN" ]; then
    echo "No token provided, skipping Telegram setup."
    exit 1
  fi

  mkdir -p "$(dirname "$TOKEN_FILE")"
  echo "${TOKEN_VAR}=${TOKEN}" > "$TOKEN_FILE"
  echo "Token saved."
fi

# 3. Launch Claude Code with Telegram channel
echo "Starting Claude Code with Telegram..."
exec claude --channels plugin:telegram@claude-plugins-official
