#!/bin/bash
set -e

# Remove stale server pid
rm -f /app/tmp/pids/server.pid

# Run migrations automatically on startup
bundle exec rails db:migrate 2>/dev/null || bundle exec rails db:create db:migrate

exec "$@"
