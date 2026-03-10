#!/bin/sh
set -e

echo "===== Starting Backend ====="
echo "Node environment: $NODE_ENV"
echo "Running Prisma migrations..."

if bunx prisma migrate deploy; then
  echo "✓ Migrations completed successfully"
else
  echo "✗ Migrations failed!"
  exit 1
fi

echo "Starting NestJS application..."
exec node dist/src/main
