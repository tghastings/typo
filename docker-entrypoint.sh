#!/bin/bash
set -e

# Remove any stale PID file
rm -f /app/tmp/pids/server.pid

# Generate secret key if not set
if [ -z "$SECRET_KEY_BASE" ]; then
    export SECRET_KEY_BASE=$(bundle exec rails secret)
    echo "Warning: SECRET_KEY_BASE was not set. Generated a temporary one."
    echo "For production, set SECRET_KEY_BASE environment variable."
fi

# Database setup
echo "Checking database..."
if [ "$DATABASE_URL" ]; then
    echo "Using DATABASE_URL for database connection"
elif [ "$TYPO_DB_ADAPTER" = "postgresql" ]; then
    echo "Using PostgreSQL database"
else
    echo "Using SQLite database"
    # Ensure SQLite database directory exists
    mkdir -p /app/db
fi

# Wait for database to be ready (for PostgreSQL)
if [ "$DATABASE_URL" ] || [ "$TYPO_DB_ADAPTER" = "postgresql" ]; then
    echo "Waiting for database..."
    for i in {1..30}; do
        bundle exec rails db:version 2>/dev/null && break
        echo "Waiting for database connection... (attempt $i/30)"
        sleep 2
    done
fi

# Run database setup
echo "Running database setup..."
# Check if blogs table exists (core table), if not, setup database
if ! bundle exec rails runner "exit(Blog.table_exists? ? 0 : 1)" 2>/dev/null; then
    echo "Database tables missing, setting up database..."
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rails db:schema:load db:seed
else
    echo "Running migrations..."
    bundle exec rails db:migrate
fi

# Seed database if empty
if bundle exec rails runner "exit(Blog.count == 0 ? 0 : 1)" 2>/dev/null; then
    echo "Seeding database..."
    bundle exec rails db:seed || true
fi

echo "Starting Typo Blog..."
exec "$@"
