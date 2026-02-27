#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SKIP_INSTALL="${SKIP_INSTALL:-0}"
RUN_BACKEND_E2E="${RUN_BACKEND_E2E:-0}"

section() {
  echo
  echo "==> $1"
}

run_backend() {
  section "Backend checks"
  cd "$ROOT_DIR/backend"
  if [[ "$SKIP_INSTALL" != "1" ]]; then
    bun install --frozen-lockfile
  fi
  bun run prisma:generate
  bun run build
  bun run test
  if [[ "$RUN_BACKEND_E2E" == "1" ]]; then
    bun run test:e2e
  fi
}

run_admin() {
  section "Console checks"
  cd "$ROOT_DIR/console"
  if [[ "$SKIP_INSTALL" != "1" ]]; then
    bun install --frozen-lockfile
  fi
  bun run lint
  bun run test
  bun run build -- --webpack
}

run_contracts() {
  section "Contracts checks"
  cd "$ROOT_DIR/contracts"
  if [[ "$SKIP_INSTALL" != "1" ]]; then
    bun install --frozen-lockfile
  fi
  bun run compile
  bun run test
}

run_mobile() {
  section "Mobile checks"
  cd "$ROOT_DIR/mobile"
  flutter pub get
  flutter analyze
  flutter test
}

section "Blocnet pre-deploy quality gate"
run_backend
run_admin
run_contracts
run_mobile

echo
echo "All pre-deploy checks passed."
