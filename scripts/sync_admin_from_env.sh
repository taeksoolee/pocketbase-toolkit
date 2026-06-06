#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

get_env_value() {
  key="$1"

  if [ ! -f "$ENV_FILE" ]; then
    return
  fi

  line=$(grep -m1 "^${key}=" "$ENV_FILE" 2>/dev/null || true)
  value=${line#*=}

  case "$value" in
    \"*\") value=${value#\"}; value=${value%\"} ;;
    \'*\') value=${value#\'}; value=${value%\'} ;;
  esac

  printf '%s' "$value"
}

PB_ADMIN_EMAIL=$(get_env_value "PB_ADMIN_EMAIL")
PB_ADMIN_PASSWORD=$(get_env_value "PB_ADMIN_PASSWORD")

if [ -z "$PB_ADMIN_EMAIL" ] || [ -z "$PB_ADMIN_PASSWORD" ]; then
  echo "[sync-admin] .env의 PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD를 먼저 설정하세요."
  exit 1
fi

echo "[sync-admin] .env 값을 기준으로 Admin 계정을 동기화합니다: $PB_ADMIN_EMAIL"
sh "$SCRIPT_DIR/create_admin.sh" "$PB_ADMIN_EMAIL" "$PB_ADMIN_PASSWORD"
