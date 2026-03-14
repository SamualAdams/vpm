#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${VPM_STATE_DIR:-$PROJECT_ROOT/.vpm}"
RUN_DIR="$STATE_DIR/run"
BACKEND_PID_FILE="$RUN_DIR/backend.pid"
FRONTEND_PID_FILE="$RUN_DIR/frontend.pid"
BACKEND_PORT="${VPM_PORT:-8000}"
FRONTEND_PORT="${VPM_FRONTEND_PORT:-5173}"

log() {
  printf '[stop] %s\n' "$1"
}

stop_pid_file() {
  local label="$1"
  local pid_file="$2"

  if [[ ! -f "$pid_file" ]]; then
    log "$label is not running"
    return 0
  fi

  local pid
  pid="$(cat "$pid_file")"

  if [[ -z "$pid" ]]; then
    rm -f "$pid_file"
    log "Removed empty pid file for $label"
    return 0
  fi

  if ! kill -0 "$pid" >/dev/null 2>&1; then
    rm -f "$pid_file"
    log "$label pid $pid was stale"
    return 0
  fi

  log "Stopping $label (pid $pid)"
  kill "$pid" >/dev/null 2>&1 || true

  for _ in $(seq 1 10); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      rm -f "$pid_file"
      log "$label stopped"
      return 0
    fi
    sleep 1
  done

  log "$label did not stop in time; sending SIGKILL"
  kill -9 "$pid" >/dev/null 2>&1 || true
  rm -f "$pid_file"
}

stop_port_listener() {
  local label="$1"
  local port="$2"

  if ! command -v lsof >/dev/null 2>&1; then
    return 0
  fi

  local pids
  pids="$(lsof -ti "tcp:$port" -sTCP:LISTEN 2>/dev/null || true)"

  if [[ -z "$pids" ]]; then
    return 0
  fi

  for pid in $pids; do
    log "Stopping $label listener on port $port (pid $pid)"
    kill "$pid" >/dev/null 2>&1 || true
    for _ in $(seq 1 10); do
      if ! kill -0 "$pid" >/dev/null 2>&1; then
        break
      fi
      sleep 1
    done
    if kill -0 "$pid" >/dev/null 2>&1; then
      log "$label listener on port $port needed SIGKILL"
      kill -9 "$pid" >/dev/null 2>&1 || true
    fi
  done
}

mkdir -p "$RUN_DIR"

stop_pid_file "frontend" "$FRONTEND_PID_FILE"
stop_pid_file "backend" "$BACKEND_PID_FILE"
stop_port_listener "frontend" "$FRONTEND_PORT"
stop_port_listener "backend" "$BACKEND_PORT"
