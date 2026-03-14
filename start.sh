#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${VPM_STATE_DIR:-$PROJECT_ROOT/.vpm}"
RUN_DIR="$STATE_DIR/run"
BACKEND_LOG="$RUN_DIR/backend.log"
FRONTEND_LOG="$RUN_DIR/frontend.log"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_HOST="${VPM_HOST:-127.0.0.1}"
BACKEND_PORT="${VPM_PORT:-8000}"
FRONTEND_HOST="${VPM_FRONTEND_HOST:-127.0.0.1}"
FRONTEND_PORT="${VPM_FRONTEND_PORT:-5173}"
BACKEND_PYTHON="$PROJECT_ROOT/.venv/bin/python"
FRONTEND_BIN="$PROJECT_ROOT/web/node_modules/vite/bin/vite.js"

log() {
  printf '[start] %s\n' "$1"
}

fail() {
  printf '[start] ERROR: %s\n' "$1" >&2
  exit 1
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    fail "Required command not found: $1"
  fi
}

start_detached() {
  local pid_file="$1"
  local log_file="$2"
  shift 2

  python3 - "$pid_file" "$log_file" "$@" <<'PY'
import subprocess
import sys

pid_file = sys.argv[1]
log_file = sys.argv[2]
command = sys.argv[3:]

with open(log_file, "ab", buffering=0) as log_handle:
    process = subprocess.Popen(
        command,
        stdin=subprocess.DEVNULL,
        stdout=log_handle,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )

with open(pid_file, "w", encoding="utf-8") as pid_handle:
    pid_handle.write(str(process.pid))
PY
}

pid_is_running() {
  local pid="$1"
  kill -0 "$pid" >/dev/null 2>&1
}

wait_for_http() {
  local url="$1"
  local label="$2"
  local attempts=60

  for _ in $(seq 1 "$attempts"); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      log "$label is ready: $url"
      return 0
    fi
    sleep 1
  done

  fail "$label did not become ready: $url"
}

stop_if_running() {
  if [[ -x "$PROJECT_ROOT/stop.sh" ]]; then
    "$PROJECT_ROOT/stop.sh" >/dev/null 2>&1 || true
  fi
}

mkdir -p "$RUN_DIR"

require_command uv
require_command npm
require_command curl
require_command python3
require_command node

log "Preparing backend dependencies"
(cd "$PROJECT_ROOT" && uv sync --group dev)

log "Preparing frontend dependencies"
(cd "$PROJECT_ROOT/web" && npm ci)

log "Running backend tests"
(cd "$PROJECT_ROOT" && uv run python -m pytest)

log "Running frontend tests"
(cd "$PROJECT_ROOT/web" && npm run test)

log "Running frontend production build"
(cd "$PROJECT_ROOT/web" && npm run build)

log "Stopping any previous local processes"
stop_if_running

log "Starting backend"
[[ -x "$BACKEND_PYTHON" ]] || fail "Backend Python not found: $BACKEND_PYTHON"
(
  cd "$PROJECT_ROOT"
  start_detached "$BACKEND_PID_FILE" "$BACKEND_LOG" env VPM_HOST="$BACKEND_HOST" VPM_PORT="$BACKEND_PORT" "$BACKEND_PYTHON" -m vpm
)

backend_pid="$(cat "$BACKEND_PID_FILE")"
if ! pid_is_running "$backend_pid"; then
  fail "Backend failed to start. See $BACKEND_LOG"
fi

wait_for_http "http://$BACKEND_HOST:$BACKEND_PORT/health" "Backend"

log "Starting frontend"
[[ -f "$FRONTEND_BIN" ]] || fail "Frontend launcher not found: $FRONTEND_BIN"
(
  cd "$PROJECT_ROOT/web"
  start_detached "$FRONTEND_PID_FILE" "$FRONTEND_LOG" node "$FRONTEND_BIN" --host "$FRONTEND_HOST" --port "$FRONTEND_PORT"
)

frontend_pid="$(cat "$FRONTEND_PID_FILE")"
if ! pid_is_running "$frontend_pid"; then
  fail "Frontend failed to start. See $FRONTEND_LOG"
fi

wait_for_http "http://$FRONTEND_HOST:$FRONTEND_PORT" "Frontend"

cat <<EOF
[start] VPM is running.
[start] Backend:  http://$BACKEND_HOST:$BACKEND_PORT
[start] Frontend: http://$FRONTEND_HOST:$FRONTEND_PORT
[start] Backend log:  $BACKEND_LOG
[start] Frontend log: $FRONTEND_LOG
[start] Stop everything with: ./stop.sh
EOF
