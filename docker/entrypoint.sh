#!/bin/sh
set -e

exec pocketbase serve --http=0.0.0.0:8090
