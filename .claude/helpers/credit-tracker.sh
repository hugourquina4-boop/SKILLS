#!/usr/bin/env bash
# credit-tracker.sh — Monitorea creditos de API y precision del modelo
# Uso: bash .claude/helpers/credit-tracker.sh <comando> [opciones]

set -euo pipefail

# ─── Rutas ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DATA_DIR="$PROJECT_ROOT/.claude-flow/credit-tracking"
mkdir -p "$DATA_DIR"

CONFIG_FILE="$DATA_DIR/config.json"
DAILY_FILE="$DATA_DIR/daily-usage.json"
SESSION_LOG="$DATA_DIR/session-log.jsonl"
PRECISION_LOG="$DATA_DIR/precision-log.jsonl"
FAILURES_LOG="$DATA_DIR/failures.jsonl"

# ─── Colores ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

# ─── Config por defecto ──────────────────────────────────────────────────────
init_config() {
  if [ ! -f "$CONFIG_FILE" ]; then
    cat > "$CONFIG_FILE" <<'EOF'
{
  "credit_alert_threshold_pct": 20,
  "credit_critical_threshold_pct": 5,
  "precision_alert_threshold": 0.90,
  "precision_critical_threshold": 0.75,
  "daily_token_limit": 500000,
  "default_model": "claude-sonnet-4-6"
}
EOF
  fi
}

get_config() {
  local key="$1"
  if command -v jq &>/dev/null && [ -f "$CONFIG_FILE" ]; then
    jq -r ".${key} // empty" "$CONFIG_FILE"
  else
    case "$key" in
      credit_alert_threshold_pct) echo 20 ;;
      credit_critical_threshold_pct) echo 5 ;;
      daily_token_limit) echo 500000 ;;
      precision_alert_threshold) echo 0.90 ;;
      *) echo "" ;;
    esac
  fi
}

# ─── Uso diario ──────────────────────────────────────────────────────────────
get_today() { date +%Y-%m-%d; }

get_daily_tokens() {
  local today; today=$(get_today)
  if command -v jq &>/dev/null && [ -f "$DAILY_FILE" ]; then
    jq -r --arg d "$today" '.[$d].tokens // 0' "$DAILY_FILE"
  else
    echo 0
  fi
}

add_tokens() {
  local tokens="$1"
  local today; today=$(get_today)
  local now; now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  if command -v jq &>/dev/null; then
    local current=0
    [ -f "$DAILY_FILE" ] && current=$(jq -r --arg d "$today" '.[$d].tokens // 0' "$DAILY_FILE")
    local new_total=$(( current + tokens ))

    local tmp; tmp=$(mktemp)
    if [ -f "$DAILY_FILE" ]; then
      jq --arg d "$today" --argjson t "$new_total" --arg ts "$now" \
        '.[$d] = {tokens: $t, last_updated: $ts}' "$DAILY_FILE" > "$tmp"
    else
      echo "{\"$today\": {\"tokens\": $new_total, \"last_updated\": \"$now\"}}" > "$tmp"
    fi
    mv "$tmp" "$DAILY_FILE"
  fi
}

# ─── Calcular estado ─────────────────────────────────────────────────────────
calculate_status() {
  local used="$1"
  local limit; limit=$(get_config daily_token_limit)
  local alert_pct; alert_pct=$(get_config credit_alert_threshold_pct)
  local critical_pct; critical_pct=$(get_config credit_critical_threshold_pct)

  local remaining=$(( limit - used ))
  local remaining_pct=$(( remaining * 100 / limit ))

  if [ "$remaining_pct" -le "$critical_pct" ]; then
    echo "CRITICO"
  elif [ "$remaining_pct" -le "$alert_pct" ]; then
    echo "ALERTA"
  else
    echo "OK"
  fi
}

format_number() {
  # Formatea numero con comas: 48320 -> 48,320
  printf "%'d" "$1" 2>/dev/null || echo "$1"
}

# ─── Comandos principales ────────────────────────────────────────────────────
cmd_status() {
  init_config
  local used; used=$(get_daily_tokens)
  local limit; limit=$(get_config daily_token_limit)
  local remaining=$(( limit - used ))
  local remaining_pct=$(( remaining * 100 / limit ))
  local alert_pct; alert_pct=$(get_config credit_alert_threshold_pct)
  local alert_tokens=$(( limit * alert_pct / 100 ))
  local status; status=$(calculate_status "$used")

  # Color segun estado
  local color="$GREEN"
  [ "$status" = "ALERTA" ] && color="$YELLOW"
  [ "$status" = "CRITICO" ] && color="$RED"

  echo -e "${BOLD}==========================================${RESET}"
  echo -e "${CYAN}${BOLD}  CREDITOS API — Estado actual${RESET}"
  echo -e "${BOLD}==========================================${RESET}"
  printf "  %-22s: %s\n" "Tokens usados hoy" "$(format_number $used)"
  printf "  %-22s: %s\n" "Limite diario" "$(format_number $limit)"
  printf "  %-22s: %s (%d%%)\n" "Restante" "$(format_number $remaining)" "$remaining_pct"
  echo -e "  Estado                 : ${color}${BOLD}$status${RESET}"
  printf "  %-22s: %d%% (%s tokens)\n" "Umbral de alerta" "$alert_pct" "$(format_number $alert_tokens)"
  echo -e "${BOLD}==========================================${RESET}"
}

cmd_daily() {
  init_config
  if ! command -v jq &>/dev/null || [ ! -f "$DAILY_FILE" ]; then
    echo -e "${YELLOW}Sin datos de uso diario aun.${RESET}"
    return
  fi

  local limit; limit=$(get_config daily_token_limit)

  echo -e "${BOLD}Fecha        Tokens       % usado   Estado${RESET}"
  echo    "--------------------------------------------"

  jq -r 'to_entries | sort_by(.key) | reverse | .[] | [.key, (.value.tokens | tostring)] | @tsv' \
    "$DAILY_FILE" | while IFS=$'\t' read -r date tokens; do
      local pct=$(( tokens * 100 / limit ))
      local remaining=$(( limit - tokens ))
      local remaining_pct=$(( 100 - pct ))
      local status; status=$(calculate_status "$tokens")
      local color="$GREEN"
      [ "$status" = "ALERTA" ] && color="$YELLOW"
      [ "$status" = "CRITICO" ] && color="$RED"
      printf "  %-12s %-12s %-9s ${color}%s${RESET}\n" \
        "$date" "$(format_number $tokens)" "${pct}%" "$status"
  done
}

cmd_precision() {
  echo -e "${BOLD}==========================================${RESET}"
  echo -e "${CYAN}${BOLD}  MONITOR DE PRECISION${RESET}"
  echo -e "${BOLD}==========================================${RESET}"

  # Contar fallos recientes (ultimas 24h)
  local failures=0
  local last_failure="ninguno"
  if command -v jq &>/dev/null && [ -f "$FAILURES_LOG" ]; then
    local cutoff; cutoff=$(date -u -d '24 hours ago' +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                          date -u -v-24H +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
                          echo "2000-01-01T00:00:00Z")
    failures=$(jq -r --arg c "$cutoff" 'select(.timestamp >= $c)' "$FAILURES_LOG" 2>/dev/null | \
               jq -rs 'length' 2>/dev/null || echo 0)
    last_failure=$(jq -rs 'last | .process + ": " + .error' "$FAILURES_LOG" 2>/dev/null || echo "ninguno")
  fi

  # Score de precision desde log
  local score="N/A"
  if command -v jq &>/dev/null && [ -f "$PRECISION_LOG" ]; then
    score=$(jq -rs '[.[].score] | if length > 0 then (add/length | (. * 100 | round) / 100 | tostring) else "N/A" end' \
            "$PRECISION_LOG" 2>/dev/null || echo "N/A")
  fi

  local threshold; threshold=$(get_config precision_alert_threshold)

  local fail_color="$GREEN"
  [ "$failures" -gt 0 ] && fail_color="$YELLOW"
  [ "$failures" -gt 5 ] && fail_color="$RED"

  printf "  %-22s: %s\n" "Score de precision" "$score"
  echo -e "  Fallos ultimas 24h     : ${fail_color}${failures}${RESET}"
  printf "  %-22s: %s\n" "Umbral precision" "$threshold"
  printf "  %-22s: %s\n" "Ultimo fallo" "$last_failure"
  echo -e "${BOLD}==========================================${RESET}"
}

cmd_log_failure() {
  local process="${1:-desconocido}"
  local error="${2:-sin descripcion}"
  local now; now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "{\"timestamp\": \"$now\", \"process\": \"$process\", \"error\": \"$error\"}" >> "$FAILURES_LOG"
  echo -e "${YELLOW}Fallo registrado: ${process} — ${error}${RESET}"
}

cmd_log_precision() {
  local score="${1:-1.0}"
  local context="${2:-general}"
  local now; now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "{\"timestamp\": \"$now\", \"score\": $score, \"context\": \"$context\"}" >> "$PRECISION_LOG"
  echo -e "${GREEN}Precision registrada: $score (contexto: $context)${RESET}"
}

cmd_log_session() {
  # Llamado por el hook Stop de Claude Code
  local now; now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local session_id="${CLAUDE_SESSION_ID:-session-$$}"
  echo "{\"timestamp\": \"$now\", \"session\": \"$session_id\"}" >> "$SESSION_LOG"
}

cmd_check_alert() {
  # Llamado por el hook SessionStart — imprime alerta si los creditos estan bajos
  init_config
  local used; used=$(get_daily_tokens)
  local status; status=$(calculate_status "$used")

  if [ "$status" = "CRITICO" ]; then
    echo -e "${RED}${BOLD}ALERTA CRITICA: Creditos de API casi agotados. Revisa tu plan de Anthropic.${RESET}"
  elif [ "$status" = "ALERTA" ]; then
    echo -e "${YELLOW}${BOLD}AVISO: Creditos de API por debajo del umbral de alerta.${RESET}"
  fi
}

cmd_set_threshold() {
  local type="${1:-}"
  local value="${2:-}"

  if [ -z "$type" ] || [ -z "$value" ]; then
    echo "Uso: credit-tracker.sh set-threshold <credits|precision> <valor>"
    exit 1
  fi

  init_config
  if command -v jq &>/dev/null; then
    local tmp; tmp=$(mktemp)
    case "$type" in
      credits)
        jq --argjson v "$value" '.credit_alert_threshold_pct = $v' "$CONFIG_FILE" > "$tmp"
        mv "$tmp" "$CONFIG_FILE"
        echo -e "${GREEN}Umbral de creditos actualizado a ${value}%${RESET}"
        ;;
      precision)
        jq --argjson v "$value" '.precision_alert_threshold = $v' "$CONFIG_FILE" > "$tmp"
        mv "$tmp" "$CONFIG_FILE"
        echo -e "${GREEN}Umbral de precision actualizado a ${value}${RESET}"
        ;;
      *)
        echo "Tipo invalido. Usa: credits o precision"
        exit 1
        ;;
    esac
  else
    echo "jq requerido para modificar configuracion"
  fi
}

cmd_config() {
  init_config
  echo -e "${BOLD}Configuracion actual:${RESET}"
  cat "$CONFIG_FILE"
}

cmd_watch() {
  local interval="${1:-300}"
  echo -e "${CYAN}Iniciando monitor continuo (cada ${interval}s). Ctrl+C para detener.${RESET}"
  while true; do
    clear
    cmd_status
    echo ""
    cmd_precision
    echo -e "\n${CYAN}Proxima actualizacion en ${interval}s...${RESET}"
    sleep "$interval"
  done
}

cmd_report() {
  local period="7d"
  local format="text"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --period) period="$2"; shift 2 ;;
      --format) format="$2"; shift 2 ;;
      *) shift ;;
    esac
  done

  echo -e "${BOLD}Reporte de creditos — periodo: $period${RESET}"
  cmd_daily
  echo ""
  cmd_precision
}

# ─── Dispatch ────────────────────────────────────────────────────────────────
COMMAND="${1:-status}"
shift || true

case "$COMMAND" in
  status)        cmd_status ;;
  daily)         cmd_daily ;;
  precision)     cmd_precision ;;
  log-failure)   cmd_log_failure "${1:-}" "${2:-}" ;;
  log-precision) cmd_log_precision "${1:-1.0}" "${2:-}" ;;
  log-session)   cmd_log_session ;;
  check-alert)   cmd_check_alert ;;
  set-threshold) cmd_set_threshold "${1:-}" "${2:-}" ;;
  config)        cmd_config ;;
  watch)         cmd_watch "${1:-300}" ;;
  report)        cmd_report "$@" ;;
  *)
    echo -e "${BOLD}Uso:${RESET} bash credit-tracker.sh <comando>"
    echo ""
    echo "Comandos disponibles:"
    echo "  status           Ver creditos disponibles hoy"
    echo "  daily            Ver uso por dia"
    echo "  precision        Ver metricas de precision del modelo"
    echo "  log-failure      Registrar fallo de proceso"
    echo "  log-precision    Registrar score de precision"
    echo "  log-session      Registrar fin de sesion (para hooks)"
    echo "  check-alert      Verificar y mostrar alertas (para hooks)"
    echo "  set-threshold    Cambiar umbrales de alerta"
    echo "  config           Ver configuracion actual"
    echo "  watch [seg]      Monitor continuo (default: 300s)"
    echo "  report           Generar reporte"
    ;;
esac
