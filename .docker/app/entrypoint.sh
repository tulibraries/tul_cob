#!/usr/bin/env bash
set -e

mkdir -p /secure-tmp/bootsnap /secure-tmp/storage

rails db:migrate 2>/dev/null || rails db:setup
rm -f /app/.internal_test_app/tmp/pids/server.pid

exec "$@"
