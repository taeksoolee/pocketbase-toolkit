#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

EMAIL="$1"
PASSWORD="$2"

is_valid_email() {
  printf '%s' "$1" | grep -Eq '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
}

is_valid_password() {
  [ "${#1}" -ge 8 ]
}

if [ -n "$EMAIL" ] && ! is_valid_email "$EMAIL"; then
  echo "[create-account] 이메일 형식이 올바르지 않습니다: $EMAIL"
  exit 1
fi

if [ -n "$PASSWORD" ] && ! is_valid_password "$PASSWORD"; then
  echo "[create-account] 비밀번호는 최소 8자 이상이어야 합니다."
  exit 1
fi

prompt_hidden() {
  prompt_text="$1"
  printf '%s' "$prompt_text"
  stty -echo
  read -r secret
  stty echo
  printf '\n'
  printf '%s' "$secret"
}

if [ -z "$EMAIL" ]; then
  while :; do
    printf "[create-account] Admin 이메일 입력: "
    read -r EMAIL
    if is_valid_email "$EMAIL"; then
      break
    fi
    echo "[create-account] 이메일 형식이 올바르지 않습니다."
  done
elif ! is_valid_email "$EMAIL"; then
  echo "[create-account] 이메일 형식이 올바르지 않습니다: $EMAIL"
  exit 1
fi

if [ -z "$PASSWORD" ]; then
  while :; do
    PASSWORD=$(prompt_hidden "[create-account] Admin 비밀번호 입력(최소 8자): ")
    if ! is_valid_password "$PASSWORD"; then
      echo "[create-account] 비밀번호는 최소 8자 이상이어야 합니다."
      continue
    fi

    CONFIRM=$(prompt_hidden "[create-account] 비밀번호 확인: ")
    if [ "$PASSWORD" != "$CONFIRM" ]; then
      echo "[create-account] 비밀번호가 일치하지 않습니다."
      continue
    fi
    break
  done
fi

echo "[create-account] Admin 계정 생성 시도: $EMAIL"
if docker compose --env-file .env -f "$ROOT_DIR/compose/docker-compose.yml" exec pocketbase \
  pocketbase admin create "$EMAIL" "$PASSWORD" >/dev/null 2>&1; then
  echo "[create-account] Admin 계정 생성 완료: $EMAIL"
  exit 0
fi

echo "[create-account] 이미 존재할 수 있어 비밀번호 업데이트 시도 중..."
if docker compose --env-file .env -f "$ROOT_DIR/compose/docker-compose.yml" exec pocketbase \
  pocketbase admin update "$EMAIL" "$PASSWORD" >/dev/null 2>&1; then
  echo "[create-account] Admin 계정 비밀번호 업데이트 완료: $EMAIL"
  exit 0
fi

echo "[create-account] Admin 계정 생성/업데이트 실패"
echo "[create-account] make logs 로 상세 로그를 확인하세요."
exit 1
