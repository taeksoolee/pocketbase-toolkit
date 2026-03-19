#!/bin/sh
set -e

if [ -n "$PB_ADMIN_EMAIL" ] && [ -n "$PB_ADMIN_PASSWORD" ]; then
  pocketbase superuser upsert "$PB_ADMIN_EMAIL" "$PB_ADMIN_PASSWORD"
fi

exec pocketbase serve --http=0.0.0.0:8090
