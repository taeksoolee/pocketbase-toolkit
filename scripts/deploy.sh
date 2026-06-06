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

# 배포 모드: cloudflare(기본) | caddy
DEPLOY_MODE="${1:-cloudflare}"

if [ -z "$DEPLOY_HOST" ] || [ -z "$DEPLOY_USER" ]; then
  echo "[deploy] DEPLOY_HOST, DEPLOY_USER 환경변수를 설정하세요."
  exit 1
fi

DEPLOY_PATH="${DEPLOY_PATH:-/opt/pocketbase}"
SSH_TARGET="$DEPLOY_USER@$DEPLOY_HOST"

echo "[deploy] 배포 시작: $SSH_TARGET:$DEPLOY_PATH (mode: $DEPLOY_MODE)"

# 서버에 배포 디렉토리가 없으면 git clone, 있으면 git pull
GIT_REMOTE_URL=$(git remote get-url origin)
# shellcheck disable=SC2029
ssh "$SSH_TARGET" "
  set -e
  if [ ! -d '$DEPLOY_PATH/.git' ]; then
    echo '[deploy] 최초 배포 — 저장소 클론 중...'
    git clone '$GIT_REMOTE_URL' '$DEPLOY_PATH'
  else
    echo '[deploy] 저장소 업데이트 중...'
    cd '$DEPLOY_PATH' && git pull
  fi
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
if [ "$DEPLOY_MODE" = "caddy" ]; then
  COMPOSE_CMD="docker compose -f compose/docker-compose.yml -f compose/docker-compose.caddy.yml"
else
  COMPOSE_CMD="docker compose -f compose/docker-compose.yml -f compose/docker-compose.prod.yml"
fi

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