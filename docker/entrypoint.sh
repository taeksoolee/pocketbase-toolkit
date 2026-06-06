#!/bin/sh
set -e

is_valid_email() {
  printf '%s' "$1" | grep -Eq '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
}

is_valid_password() {
  [ "${#1}" -ge 8 ]
}

if [ -n "$PB_ADMIN_EMAIL" ] || [ -n "$PB_ADMIN_PASSWORD" ]; then
  if [ -z "$PB_ADMIN_EMAIL" ] || [ -z "$PB_ADMIN_PASSWORD" ]; then
    echo "[entrypoint] PB_ADMIN_EMAIL, PB_ADMIN_PASSWORD는 함께 설정해야 합니다."
    exit 1
  fi

  if ! is_valid_email "$PB_ADMIN_EMAIL"; then
    echo "[entrypoint] PB_ADMIN_EMAIL 형식이 올바르지 않습니다: $PB_ADMIN_EMAIL"
    exit 1
  fi

  if ! is_valid_password "$PB_ADMIN_PASSWORD"; then
    echo "[entrypoint] PB_ADMIN_PASSWORD는 최소 8자 이상이어야 합니다."
    exit 1
  fi

  pocketbase superuser upsert "$PB_ADMIN_EMAIL" "$PB_ADMIN_PASSWORD"
fi

exec pocketbase serve --http=0.0.0.0:8090
