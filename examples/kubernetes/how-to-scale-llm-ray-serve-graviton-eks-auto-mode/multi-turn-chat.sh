#!/bin/bash
#
# Simple multi-turn chat client for the vLLM OpenAI-compatible API.
#
# First port-forward the Ray Serve Service to your laptop:
#   kubectl -n ray-vllm port-forward svc/qwen-vllm-serve-svc 8000:8000
# then, in another terminal, export the API key and run this script:
#   export TOKEN=$(kubectl -n ray-vllm get secret ray-vllm-api-key -o jsonpath='{.data.api-key}' | base64 -d)
#   ./multi-turn-chat.sh
#
# Requires: curl, jq

API_URL="http://localhost:8000/v1/chat/completions"
TOKEN="${TOKEN:?export TOKEN with the api-key from the ray-vllm-api-key Secret}"
MODEL="${MODEL:-Qwen/Qwen3-4B-Instruct-2507}"

# Colors
BOLD="\033[1m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
DIM="\033[2m"
RESET="\033[0m"

MESSAGES='[]'

clear
echo -e "${BOLD}╔══════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║      Chat with ${CYAN}${MODEL}${RESET}${BOLD}       ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════╝${RESET}"
echo -e "${DIM}  Type your message and press Enter. Leave blank to exit.${RESET}"
echo ""

while true; do
  echo -e "${CYAN}${BOLD}You:${RESET} \c"
  read USER_INPUT
  [[ -z "$USER_INPUT" ]] && echo -e "\n${DIM}Goodbye!${RESET}\n" && break

  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$USER_INPUT" \
    '. + [{"role": "user", "content": $content}]')

  echo -e "${DIM}  thinking...${RESET}"

  RESPONSE=$(curl -sH "Authorization: Bearer $TOKEN" "$API_URL" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --argjson messages "$MESSAGES" --arg model "$MODEL" '{
      model: $model,
      messages: $messages,
      max_tokens: 100
    }')")

  ASSISTANT_MSG=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // "⚠️  No response received."')

  # Overwrite "thinking..." line
  echo -e "\033[1A\033[2K"
  echo -e "${GREEN}${BOLD}Assistant:${RESET}"
  echo -e "  ${ASSISTANT_MSG}"
  echo -e "${DIM}  ────────────────────────────────────${RESET}"
  echo ""

  MESSAGES=$(echo "$MESSAGES" | jq --arg content "$ASSISTANT_MSG" \
    '. + [{"role": "assistant", "content": $content}]')
done
