#!/usr/bin/env bash
set -e

rails db:migrate 2>/dev/null || rails db:setup
rm -f /app/.internal_test_app/tmp/pids/server.pid

exec "$@"
