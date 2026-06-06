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

  # Read KEY=value literally (without evaluating shell expressions).
  line=$(grep -m1 "^${key}=" "$ENV_FILE" 2>/dev/null || true)
  value=${line#*=}

  # Trim matching single/double quotes if present.
  case "$value" in
    \"*\") value=${value#\"}; value=${value%\"} ;;
    \'*\') value=${value#\'}; value=${value%\'} ;;
  esac

  printf '%s' "$value"
}

PB_ADMIN_EMAIL=$(get_env_value "PB_ADMIN_EMAIL")
PB_ADMIN_PASSWORD=$(get_env_value "PB_ADMIN_PASSWORD")
PB_HOST_PORT=$(get_env_value "PB_HOST_PORT")
PB_URL=$(get_env_value "PB_URL")

if [ -z "$PB_HOST_PORT" ]; then
  PB_HOST_PORT=8090
fi

if [ -z "$PB_URL" ]; then
  PB_URL="http://localhost:${PB_HOST_PORT}"
fi

if [ -z "$PB_ADMIN_EMAIL" ] || [ -z "$PB_ADMIN_PASSWORD" ]; then
  echo "[list-admins] .env의 PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD를 먼저 설정하세요."
  exit 1
fi

echo "[list-admins] 관리자 인증 중..."
AUTH_RESPONSE=$(curl -s -X POST "$PB_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$PB_ADMIN_EMAIL\",\"password\":\"$PB_ADMIN_PASSWORD\"}")

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "[list-admins] 인증 실패: $AUTH_RESPONSE"
  exit 1
fi

fetch_with_code() {
  url="$1"
  curl -s -w "\n%{http_code}" "$url" -H "Authorization: $TOKEN"
}

RESPONSE=$(fetch_with_code "$PB_URL/api/admins?perPage=200")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  RESPONSE=$(fetch_with_code "$PB_URL/api/collections/_superusers/records?perPage=200")
  HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  BODY=$(echo "$RESPONSE" | sed '$d')
fi

if [ "$HTTP_CODE" != "200" ]; then
  echo "[list-admins] 목록 조회 실패 (HTTP $HTTP_CODE): $BODY"
  exit 1
fi

EMAILS=$(echo "$BODY" | grep -o '"email":"[^"]*"' | cut -d'"' -f4 | sort -u)

if [ -z "$EMAILS" ]; then
  echo "[list-admins] admin 이메일을 찾지 못했습니다. 원본 응답:"
  echo "$BODY"
  exit 1
fi

echo "[list-admins] Admin 계정 목록"
i=1
for email in $EMAILS; do
  echo "  $i) $email"
  i=$((i + 1))
done
