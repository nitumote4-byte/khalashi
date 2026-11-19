#!/bin/sh
# Run migrations then start the API. DATABASE_URL must be set by the host.
set -e
echo "Running migrations..."
node dist/db/migrate.js
echo "Starting API on PORT=${PORT:-3000} OTP_PROVIDER=${OTP_PROVIDER:-mock}"
exec node dist/index.js
