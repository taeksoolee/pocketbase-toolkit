#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  . "$ROOT_DIR/.env"
  set +a
fi

PB_URL="${PB_URL:-http://localhost:${PB_HOST_PORT:-8090}}"
SNAPSHOT_DIR="${SNAPSHOT_DIR:-$ROOT_DIR/snapshots}"

if [ -z "$PB_ADMIN_EMAIL" ] || [ -z "$PB_ADMIN_PASSWORD" ]; then
  echo "[db-snapshot] .env의 PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD를 먼저 설정하세요."
  exit 1
fi

auth_admin() {
  auth_email="$1"
  auth_password="$2"
  AUTH_RESPONSE=$(curl -s -X POST "$PB_URL/api/admins/auth-with-password" \
    -H "Content-Type: application/json" \
    -d "{\"identity\":\"$auth_email\",\"password\":\"$auth_password\"}")

  TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)
  [ -n "$TOKEN" ]
}

mkdir -p "$SNAPSHOT_DIR"

echo "[db-snapshot] 관리자 인증 중..."
if ! auth_admin "$PB_ADMIN_EMAIL" "$PB_ADMIN_PASSWORD"; then
  echo "[db-snapshot] .env 관리자 인증 실패: $AUTH_RESPONSE"
  exit 1
fi

echo "[db-snapshot] 서버 스냅샷 생성 요청 중..."
curl -s -X POST "$PB_URL/api/backups" \
  -H "Authorization: $TOKEN" >/dev/null

sleep 2

BACKUPS_RESPONSE=$(curl -s "$PB_URL/api/backups" \
  -H "Authorization: $TOKEN")

BACKUP_KEY=$(echo "$BACKUPS_RESPONSE" | grep -o '"key":"[^"]*"' | tail -1 | cut -d'"' -f4)

if [ -z "$BACKUP_KEY" ]; then
  echo "[db-snapshot] 백업 키 조회 실패"
  exit 1
fi

FILE_TOKEN_RESPONSE=$(curl -s -X POST "$PB_URL/api/files/token" \
  -H "Authorization: $TOKEN")
FILE_TOKEN=$(echo "$FILE_TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$FILE_TOKEN" ]; then
  echo "[db-snapshot] 파일 토큰 발급 실패"
  exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAPSHOT_FILE="$SNAPSHOT_DIR/db_snapshot_${TIMESTAMP}.zip"

echo "[db-snapshot] 다운로드 중: $BACKUP_KEY"
curl -s -L \
  "$PB_URL/api/backups/$BACKUP_KEY?token=$FILE_TOKEN" \
  -o "$SNAPSHOT_FILE"

echo "[db-snapshot] 완료: $SNAPSHOT_FILE"
echo "[db-snapshot] 참고: 이 파일은 분석/디버깅 용도이며 운영 DB 직접 수정은 권장하지 않습니다."
