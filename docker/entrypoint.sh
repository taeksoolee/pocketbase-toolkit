#!/bin/sh
set -e

exec pocketbase serve --http=0.0.0.0:${PB_HOST_PORT:-8090}
