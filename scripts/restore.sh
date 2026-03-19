#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  . "$ROOT_DIR/.env"
  set +a
fi

PB_URL="${PB_URL:-http://localhost:8090}"
BACKUP_DIR="${BACKUP_DIR:-$ROOT_DIR/backups}"

# 로컬 백업 파일 목록 출력
BACKUP_FILES=$(ls -t "$BACKUP_DIR"/backup_*.zip 2>/dev/null || true)

if [ -z "$BACKUP_FILES" ]; then
  echo "[restore] 복원할 백업 파일이 없습니다: $BACKUP_DIR"
  exit 1
fi

echo "[restore] 사용 가능한 백업 목록:"
echo ""
i=1
for f in $BACKUP_FILES; do
  SIZE=$(du -h "$f" | cut -f1)
  echo "  $i) $(basename "$f") ($SIZE)"
  i=$((i + 1))
done
echo ""

printf "[restore] 복원할 번호 입력: "
read -r SELECTION

TARGET_FILE=$(echo "$BACKUP_FILES" | sed -n "${SELECTION}p")

if [ -z "$TARGET_FILE" ]; then
  echo "[restore] 잘못된 선택입니다."
  exit 1
fi

echo "[restore] 선택된 파일: $(basename "$TARGET_FILE")"
printf "[restore] 계속 진행하면 현재 데이터가 덮어씁니다. 진행하시겠습니까? (y/N): "
read -r CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "[restore] 취소되었습니다."
  exit 0
fi

echo "[restore] 인증 중..."
AUTH_RESPONSE=$(curl -s -X POST "$PB_URL/api/admins/auth-with-password" \
  -H "Content-Type: application/json" \
  -d "{\"identity\":\"$PB_ADMIN_EMAIL\",\"password\":\"$PB_ADMIN_PASSWORD\"}")

TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "[restore] 인증 실패: $AUTH_RESPONSE"
  exit 1
fi

BACKUP_FILENAME="$(basename "$TARGET_FILE")"

echo "[restore] 서버에 백업 파일 업로드 중..."
curl -s -X POST "$PB_URL/api/backups/upload" \
  -H "Authorization: $TOKEN" \
  -F "file=@$TARGET_FILE" > /dev/null

echo "[restore] 복원 실행 중..."
curl -s -X POST "$PB_URL/api/backups/$BACKUP_FILENAME/restore" \
  -H "Authorization: $TOKEN" > /dev/null

echo "[restore] 복원 완료. 서버가 재시작됩니다."
echo "[restore] 잠시 후 $PB_URL/_/ 에 접속하여 확인하세요."
