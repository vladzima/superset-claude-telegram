#!/usr/bin/env bash
set -euo pipefail

# Close the Telegram topic associated with this workspace.
# Called by Superset when the workspace is terminated.

# Debug log for diagnosing teardown issues
TEARDOWN_LOG="/tmp/teardown-debug.log"
echo "=== teardown.sh $(date) ===" >> "$TEARDOWN_LOG"
echo "pwd: $(pwd)" >> "$TEARDOWN_LOG"
echo "SUPERSET_WORKSPACE_NAME: ${SUPERSET_WORKSPACE_NAME:-<unset>}" >> "$TEARDOWN_LOG"
echo "git branch: $(git branch --show-current 2>/dev/null || echo '<failed>')" >> "$TEARDOWN_LOG"

TOKEN_FILE="$HOME/.claude/channels/telegram/.env"
DAEMON_TOPICS="$HOME/.claude/channels/telegram/daemon/topics"

# Load bot token
if [ ! -f "$TOKEN_FILE" ]; then
  exit 0
fi
TOKEN=$(grep "^TELEGRAM_BOT_TOKEN=" "$TOKEN_FILE" | sed 's/^TELEGRAM_BOT_TOKEN=//')
if [ -z "$TOKEN" ]; then
  exit 0
fi

# Derive topic name (same logic as setup.sh)
BRANCH="$(git branch --show-current 2>/dev/null)" || true
TOPIC_NAME="${SUPERSET_WORKSPACE_NAME:-${BRANCH:-$(basename "$(pwd)")}}"
echo "TOPIC_NAME resolved to: $TOPIC_NAME" >> "$TEARDOWN_LOG"

# Find the topic's thread ID from persisted metadata
THREAD_ID=""
CHAT_ID=""
if [ -d "$DAEMON_TOPICS" ]; then
  for dir in "$DAEMON_TOPICS"/*/; do
    meta="${dir}meta.json"
    if [ -f "$meta" ]; then
      read -r name thread_id chat_id < <(
        python3 - "$meta" <<'PYEOF'
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get('topicName', ''), d.get('threadId', ''), d.get('chatId', ''))
PYEOF
      ) || continue
      if [ "$name" = "$TOPIC_NAME" ]; then
        THREAD_ID="$thread_id"
        CHAT_ID="$chat_id"
        break
      fi
    fi
  done
fi

if [ -z "$THREAD_ID" ] || [ -z "$CHAT_ID" ]; then
  echo "No topic found for workspace '$TOPIC_NAME', skipping."
  echo "RESULT: no match found" >> "$TEARDOWN_LOG"
  exit 0
fi
echo "RESULT: matched thread_id=$THREAD_ID chat_id=$CHAT_ID" >> "$TEARDOWN_LOG"

# Close the topic (archive, not delete — preserves conversation history)
echo "Closing Telegram topic '$TOPIC_NAME' (thread_id: $THREAD_ID)..."
curl -s -X POST "https://api.telegram.org/bot${TOKEN}/closeForumTopic" \
  -d "chat_id=${CHAT_ID}" \
  -d "message_thread_id=${THREAD_ID}" > /dev/null 2>&1 || true

echo "Topic closed."
