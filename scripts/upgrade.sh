#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ -f "$ROOT_DIR/.env" ]; then
  set -a
  . "$ROOT_DIR/.env"
  set +a
fi

NEW_VERSION="$1"

if [ -z "$NEW_VERSION" ]; then
  echo "사용법: $0 <새 버전>"
  echo "예시: $0 0.23.0"
  exit 1
fi

CURRENT_VERSION="${PB_VERSION:-0.22.4}"

if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
  echo "[upgrade] 이미 $CURRENT_VERSION 버전입니다."
  exit 0
fi

echo "[upgrade] $CURRENT_VERSION → $NEW_VERSION 업그레이드 시작"

# 1. 업그레이드 전 백업
echo "[upgrade] 1/4 업그레이드 전 백업 실행..."
"$SCRIPT_DIR/backup.sh"

# 2. .env 버전 변경
echo "[upgrade] 2/4 PB_VERSION 변경: $CURRENT_VERSION → $NEW_VERSION"
sed -i.bak "s/^PB_VERSION=.*/PB_VERSION=$NEW_VERSION/" "$ROOT_DIR/.env"
rm -f "$ROOT_DIR/.env.bak"

# 3. 컨테이너 재빌드 및 재시작
echo "[upgrade] 3/4 컨테이너 재빌드 및 재시작..."
cd "$ROOT_DIR"
docker compose -f compose/docker-compose.yml down
docker compose -f compose/docker-compose.yml up -d --build

# 4. 헬스체크 (최대 60초 대기)
echo "[upgrade] 4/4 헬스체크 대기 중..."
PB_URL="${PB_URL:-http://localhost:${PB_HOST_PORT:-8090}}"
RETRIES=12
INTERVAL=5

for i in $(seq 1 $RETRIES); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$PB_URL/api/health" 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo "[upgrade] 업그레이드 완료: $NEW_VERSION"
    exit 0
  fi
  echo "[upgrade] 헬스체크 대기 중... ($i/$RETRIES)"
  sleep $INTERVAL
done

# 헬스체크 실패 → 롤백
echo "[upgrade] 헬스체크 실패. $CURRENT_VERSION 으로 롤백 중..."
sed -i.bak "s/^PB_VERSION=.*/PB_VERSION=$CURRENT_VERSION/" "$ROOT_DIR/.env"
rm -f "$ROOT_DIR/.env.bak"

docker compose -f compose/docker-compose.yml down
docker compose -f compose/docker-compose.yml up -d --build

echo "[upgrade] 롤백 완료: $CURRENT_VERSION"
exit 1
