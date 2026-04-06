#!/bin/bash
# =============================================================================
# Claude Code Status Line Wrapper
# 自前スクリプト（Line 1-3）+ ccusage（Line 4-5）を統合
# =============================================================================

# --- JSON入力を一度だけ読む ---
INPUT=$(cat)

# =============================================================================
# ANSI カラーコード
# =============================================================================
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
WHITE='\033[97m'
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
BLUE='\033[34m'
MAGENTA='\033[35m'
GRAY='\033[90m'

# =============================================================================
# JSONフィールド抽出
# =============================================================================
FOLDER=$(basename "$(echo "$INPUT" | jq -r '.workspace.current_dir // "?"')")
MODEL_ID=$(echo "$INPUT"   | jq -r '.model.id // "?"')
MODEL=$(echo "$INPUT"      | jq -r '.model.display_name // "?"')
COST=$(echo "$INPUT"       | jq -r '.cost.total_cost_usd // 0')
TOTAL_MS=$(echo "$INPUT"   | jq -r '.cost.total_duration_ms // 0')
API_MS=$(echo "$INPUT"     | jq -r '.cost.total_api_duration_ms // 0')
LINES_ADD=$(echo "$INPUT"  | jq -r '.cost.total_lines_added // 0')
LINES_DEL=$(echo "$INPUT"  | jq -r '.cost.total_lines_removed // 0')
CTX_PCT=$(echo "$INPUT"    | jq -r '.context_window.used_percentage // 0')
TOT_IN=$(echo "$INPUT"     | jq -r '.context_window.total_input_tokens // 0')
TOT_OUT=$(echo "$INPUT"    | jq -r '.context_window.total_output_tokens // 0')
CTX_SIZE=$(echo "$INPUT"   | jq -r '.context_window.context_window_size // 200000')
CUR_IN=$(echo "$INPUT"     | jq -r '.context_window.current_usage.input_tokens // 0')
CACHE_CREATE=$(echo "$INPUT" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
CACHE_READ=$(echo "$INPUT"   | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')

# =============================================================================
# 計算
# =============================================================================

# ---- コスト ----
COST_FMT=$(printf '%.3f' "$COST")

# ---- 経過時間 ----
TOTAL_SEC=$(echo "$TOTAL_MS / 1000" | bc 2>/dev/null || echo 0)
H=$((TOTAL_SEC / 3600))
M=$(( (TOTAL_SEC % 3600) / 60 ))
S=$((TOTAL_SEC % 60))
if [ "$H" -gt 0 ]; then
  ELAPSED=$(printf '%dh%02dm' "$H" "$M")
else
  ELAPSED=$(printf '%dm%02ds' "$M" "$S")
fi

# ---- API待ち割合 ----
if [ "$TOTAL_MS" -gt 0 ]; then
  API_PCT=$(echo "scale=0; $API_MS * 100 / $TOTAL_MS" | bc 2>/dev/null || echo 0)
else
  API_PCT=0
fi

# ---- モデル別トークン単価 ($IN/$OUT per 1M tokens) ----
case "$MODEL_ID" in
  *"opus-4"*|*"opus-4-6"*)
    PRICE_IN=15; PRICE_OUT=75 ;;
  *"sonnet-4"*|*"sonnet-4-6"*)
    PRICE_IN=3; PRICE_OUT=15 ;;
  *"haiku"*)
    PRICE_IN=1; PRICE_OUT=5 ;;
  *)
    PRICE_IN="?"; PRICE_OUT="?" ;;
esac

# ---- キャッシュヒット率 ----
TOTAL_IN_TOKENS=$((CUR_IN + CACHE_CREATE + CACHE_READ))
if [ "$TOTAL_IN_TOKENS" -gt 0 ]; then
  CACHE_HIT=$(echo "scale=0; $CACHE_READ * 100 / $TOTAL_IN_TOKENS" | bc 2>/dev/null || echo 0)
else
  CACHE_HIT=0
fi

# ---- IN/OUT トークン (単位付き) ----
format_tokens() {
  local n=$1
  if [ "$n" -ge 1000000 ]; then
    echo "$(echo "scale=1; $n / 1000000" | bc)M"
  elif [ "$n" -ge 1000 ]; then
    echo "$(echo "scale=1; $n / 1000" | bc)k"
  else
    echo "$n"
  fi
}
IN_FMT=$(format_tokens "$TOT_IN")
OUT_FMT=$(format_tokens "$TOT_OUT")

# ---- コード変更 ----
DELTA=$((LINES_ADD - LINES_DEL))
if [ "$DELTA" -ge 0 ]; then
  DELTA_STR="+${DELTA}"
  DELTA_COLOR=$GREEN
else
  DELTA_STR="${DELTA}"
  DELTA_COLOR=$RED
fi

# ---- ctxバー (20文字、色付き) ----
CTX_INT=$(printf '%.0f' "$CTX_PCT")
if   [ "$CTX_INT" -lt 50 ]; then BAR_COLOR=$GREEN
elif [ "$CTX_INT" -lt 80 ]; then BAR_COLOR=$YELLOW
else                               BAR_COLOR=$RED
fi
BAR_FILLED=$(( CTX_INT / 5 ))  # 20文字 → 5%ごとに1文字
BAR_FILLED=$((BAR_FILLED > 20 ? 20 : BAR_FILLED))
BAR=""
for i in $(seq 1 20); do
  if [ "$i" -le "$BAR_FILLED" ]; then BAR="${BAR}█"; else BAR="${BAR}░"; fi
done

# =============================================================================
# Line 1: セッション情報
# devenv — フォルダ名  モデル  Reasoning Effort:?  ($IN/$OUTm)  $コスト  時間 (API%)
# =============================================================================
printf "${GRAY}devenv${RESET} ${BOLD}${WHITE}— ${FOLDER}${RESET}  "
printf "${CYAN}${MODEL}${RESET}  "
printf "${DIM}Reasoning Effort:?${RESET}  "
printf "${GRAY}(\$${PRICE_IN}/\$${PRICE_OUT}M)${RESET}  "
printf "${BOLD}\$${COST_FMT}${RESET}  "
printf "${DIM}${ELAPSED} (${API_PCT}%%API)${RESET}"
printf "\n"

# =============================================================================
# Line 2: コンテキスト
# ctx ████░░░░░░ XX%  IN:XXk OUT:XXk  cache:XX%
# =============================================================================
printf "${GRAY}ctx${RESET} ${BAR_COLOR}${BAR}${RESET} ${BAR_COLOR}${CTX_INT}%%${RESET}  "
printf "${GRAY}IN:${RESET}${IN_FMT} ${GRAY}OUT:${RESET}${OUT_FMT}  "
printf "${GRAY}cache:${RESET}${CACHE_HIT}%%"
printf "\n"

# =============================================================================
# Line 3: コード変更
# +追加 -削除 (Δ純増減)
# =============================================================================
printf "${GREEN}+${LINES_ADD}${RESET} ${RED}-${LINES_DEL}${RESET} ${GRAY}(Δ${RESET}${DELTA_COLOR}${DELTA_STR}${RESET}${GRAY})${RESET}"
printf "\n"

# =============================================================================
# Line 4-5: ccusage によるサブスク使用率
# ccusage がインストールされていない場合はプレースホルダーを表示
# =============================================================================

# ccusageを実行（stdin に元のJSONを渡す）
CCUSAGE_OUTPUT=""

if command -v bunx &>/dev/null; then
  CCUSAGE_OUTPUT=$(echo "$INPUT" | bunx ccusage statusline 2>/dev/null)
elif command -v npx &>/dev/null; then
  CCUSAGE_OUTPUT=$(echo "$INPUT" | npx --yes ccusage statusline 2>/dev/null)
fi

if [ -n "$CCUSAGE_OUTPUT" ]; then
  # ccusageの出力をそのまま表示（Line 4-5）
  echo "$CCUSAGE_OUTPUT"
else
  # ccusageが使えない場合のフォールバック
  printf "${GRAY}ses:${RESET} ${DIM}-- (ccusage未検出)${RESET}  ${GRAY}wk:${RESET} ${DIM}--${RESET}"
  printf "\n"
  printf "${DIM}  ヒント: bun/npxをインストールするとses/wk使用率が表示されます${RESET}"
  printf "\n"
fi