#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/compose.yaml"
ENV_FILE="${SCRIPT_DIR}/.env"
DATA_DIR="/Users/wang/workspace/docker_work/redis"

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  start       Create data directory and start Redis in background
  stop        Stop the running Redis container
  restart     Restart the running Redis container
  status      Show compose status
  ps          Alias of status
  logs        Show logs, use -f to follow
  delete      Remove compose resources and delete host data directory
  help        Show this help message

Options:
  -f, --follow  Follow logs when using logs command
  -y, --yes     Skip confirmation when using delete command
EOF
}

require_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "docker command not found"
    exit 1
  fi
  if ! docker compose version >/dev/null 2>&1; then
    echo "docker compose is not available"
    exit 1
  fi
}

compose() {
  docker compose -f "${COMPOSE_FILE}" --env-file "${ENV_FILE}" "$@"
}

confirm_delete() {
  local answer
  echo "This will remove the Redis container, network, and host data directory:"
  echo "  ${DATA_DIR}"
  printf "Type YES to continue: "
  read -r answer
  if [[ "${answer}" != "YES" ]]; then
    echo "Delete cancelled."
    exit 0
  fi
}

remove_data_dir() {
  if [[ -d "${DATA_DIR}" ]]; then
    rm -rf "${DATA_DIR}"
    echo "Removed host data directory: ${DATA_DIR}"
  else
    echo "Host data directory does not exist: ${DATA_DIR}"
  fi
}

start() {
  mkdir -p "${DATA_DIR}"
  compose up -d
}

stop() {
  compose stop
}

restart() {
  compose restart
}

status() {
  compose ps
}

logs() {
  if [[ "${FOLLOW_LOGS:-0}" == "1" ]]; then
    compose logs -f --tail=200
  else
    compose logs --tail=200
  fi
}

delete_stack() {
  if [[ "${SKIP_CONFIRM:-0}" != "1" ]]; then
    confirm_delete
  fi
  compose down --remove-orphans
  remove_data_dir
}

main() {
  require_docker

  local command="${1:-help}"
  shift || true

  FOLLOW_LOGS=0
  SKIP_CONFIRM=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -f|--follow)
        FOLLOW_LOGS=1
        ;;
      -y|--yes)
        SKIP_CONFIRM=1
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
  done

  case "${command}" in
    start|up)
      start
      ;;
    stop)
      stop
      ;;
    restart)
      restart
      ;;
    status|ps)
      status
      ;;
    logs)
      logs
      ;;
    delete|down|rm)
      delete_stack
      ;;
    help|-h|--help)
      usage
      ;;
    *)
      echo "Unknown command: ${command}"
      usage
      exit 1
      ;;
  esac
}

main "$@"
