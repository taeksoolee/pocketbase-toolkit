#!/bin/sh
set -e

# 스크립트 위치 기준으로 .env 로드
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  . "$ROOT_DIR/.env"
  set +a
fi

PB_URL="${PB_URL:-http://localhost:8090}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

mkdir -p "$BACKUP_DIR"

echo "[backup] 인증 중..."
AUTH_RESPONSE=$(curl -s -X POST "$PB_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$PB_ADMIN_EMAIL\",\"password\":\"$PB_ADMIN_PASSWORD\"}")

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "[backup] 인증 실패: $AUTH_RESPONSE"
  exit 1
fi

echo "[backup] 백업 생성 중..."
curl -s -X POST "$PB_URL/api/backups" \
  -H "Authorization: $TOKEN" > /dev/null

sleep 2

echo "[backup] 백업 목록 조회 중..."
BACKUPS_RESPONSE=$(curl -s "$PB_URL/api/backups" \
  -H "Authorization: $TOKEN")

# 가장 최근 백업 키 추출
BACKUP_KEY=$(echo "$BACKUPS_RESPONSE" | grep -o '"key":"[^"]*"' | tail -1 | cut -d'"' -f4)

if [ -z "$BACKUP_KEY" ]; then
  echo "[backup] 백업 파일 조회 실패"
  exit 1
fi

echo "[backup] 다운로드 중: $BACKUP_KEY"

# 파일 다운로드용 단기 토큰 발급
FILE_TOKEN_RESPONSE=$(curl -s -X POST "$PB_URL/api/files/token" \
  -H "Authorization: $TOKEN")
FILE_TOKEN=$(echo "$FILE_TOKEN_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.zip"

curl -s -L \
  "$PB_URL/api/backups/$BACKUP_KEY?token=$FILE_TOKEN" \
  -o "$BACKUP_FILE"

echo "[backup] 저장 완료: $BACKUP_FILE"

# S3 업로드 (선택)
if [ -n "$BACKUP_S3_BUCKET" ]; then
  echo "[backup] S3 업로드 중..."
  aws s3 cp "$BACKUP_FILE" "s3://$BACKUP_S3_BUCKET/$(basename "$BACKUP_FILE")" \
    --region "${BACKUP_S3_REGION:-us-east-1}"
  echo "[backup] S3 업로드 완료: s3://$BACKUP_S3_BUCKET/$(basename "$BACKUP_FILE")"
fi

# 오래된 백업 삭제
find "$BACKUP_DIR" -name "backup_*.zip" -mtime +"$BACKUP_RETENTION_DAYS" -delete 2>/dev/null || true
echo "[backup] ${BACKUP_RETENTION_DAYS}일 이전 백업 정리 완료"
