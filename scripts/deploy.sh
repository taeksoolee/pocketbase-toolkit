#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
FORCE_SYNC_ENV="${FORCE_SYNC_ENV:-0}"

if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "[deploy] $ROOT_DIR/.env 파일이 없습니다."
  echo "[deploy] 로컬 배포는 .env를 만들고, CI 배포는 워크フル로우에서 .env 생성 단계를 확인하세요."
  exit 1
fi

set -a
# shellcheck source=/dev/null
. "$ROOT_DIR/.env"
set +a

if [ -z "$DEPLOY_HOST" ] || [ -z "$DEPLOY_USER" ]; then
  echo "[deploy] DEPLOY_HOST, DEPLOY_USER 환경변수를 설정하세요."
  exit 1
fi

DEPLOY_PATH="${DEPLOY_PATH:-/opt/pocketbase}"
SSH_TARGET="$DEPLOY_USER@$DEPLOY_HOST"

echo "[deploy] 배포 시작: $SSH_TARGET:$DEPLOY_PATH"

echo "[deploy] 소스코드 압축 중..."
# .git이나 .github 같은 불필요한 폴더를 제외하고 하나의 압축파일로 만듭니다.
tar -czf "$SCRIPT_DIR/release.tar.gz" -C "$ROOT_DIR" \
  --exclude='.git' \
  --exclude='.github' \
  --exclude='scripts/release.tar.gz' .

echo "[deploy] 소스코드 서버로 전송 및 압축 해제 중..."
# 서버에 디렉토리가 없으면 만들고, 압축파일을 보낸 뒤 서버 안에서 해제합니다.
ssh "$SSH_TARGET" "mkdir -p '$DEPLOY_PATH'"
scp "$SCRIPT_DIR/release.tar.gz" "$SSH_TARGET:$DEPLOY_PATH/release.tar.gz"

ssh "$SSH_TARGET" "
  set -e
  cd '$DEPLOY_PATH'
  tar -xzf release.tar.gz
  rm release.tar.gz
"

# .env 파일 동기화
echo "[deploy] .env 파일 동기화 중..."
if [ "$FORCE_SYNC_ENV" = "1" ]; then
  scp "$ROOT_DIR/.env" "$SSH_TARGET:$DEPLOY_PATH/.env"
  echo "[deploy] .env 강제 동기화 완료"
else
  ssh "$SSH_TARGET" "[ -f '$DEPLOY_PATH/.env' ] && echo 'skip' || echo 'missing'" | grep -q "missing" && \
    scp "$ROOT_DIR/.env" "$SSH_TARGET:$DEPLOY_PATH/.env" && \
    echo "[deploy] .env 전송 완료" || \
    echo "[deploy] .env 이미 존재 — 서버 파일 유지"
fi

# 컨테이너 재시작
echo "[deploy] 컨테이너 재시작 중..."
COMPOSE_CMD="docker compose --env-file .env -f compose/docker-compose.yml -f compose/docker-compose.prod.yml"

ssh "$SSH_TARGET" "
  set -e
  cd '$DEPLOY_PATH'
  $COMPOSE_CMD pull 2>/dev/null || true
  $COMPOSE_CMD up -d --build
"

# 헬스체크 (최대 60초 대기)
echo "[deploy] 헬스체크 대기 중..."
RETRIES=12
INTERVAL=5
HEALTH_PORT="${PB_HOST_PORT:-8090}"

for i in $(seq 1 $RETRIES); do
  # shellcheck disable=SC2029
  STATUS=$(ssh "$SSH_TARGET" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:$HEALTH_PORT/api/health 2>/dev/null || echo 000")
  if [ "$STATUS" = "200" ]; then
    echo "[deploy] 배포 완료"
    exit 0
  fi
  echo "[deploy] 헬스체크 대기 중... ($i/$RETRIES)"
  sleep $INTERVAL
done

echo "[deploy] 헬스체크 실패. 서버 로그를 확인하세요:"
echo "  ssh $SSH_TARGET 'cd $DEPLOY_PATH && $COMPOSE_CMD logs --tail=50'"
exit 1