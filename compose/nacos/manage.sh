#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

load_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo ".env not found: ${ENV_FILE}"
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a

  HOST_WORK_DIR="${HOST_WORK_DIR:-/Users/wang/workspace/docker_work/nacos}"
  HOST_LOG_DIR="${HOST_WORK_DIR}/logs"
}

usage() {
  cat <<EOF
Usage: $(basename "$0") <command> [options]

Commands:
  start       Start Nacos with docker run
  stop        Stop the Nacos container
  restart     Restart the Nacos container
  recreate    Remove existing container and create a new one from current .env
  status      Show container status
  logs        Show logs, use -f to follow
  print-run   Print the exact docker run command
  delete      Remove the container and local Nacos log directory
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
}

container_exists() {
  docker container inspect "${NACOS_CONTAINER_NAME}" >/dev/null 2>&1
}

container_running() {
  [[ "$(docker inspect -f '{{.State.Running}}' "${NACOS_CONTAINER_NAME}" 2>/dev/null || true)" == "true" ]]
}

build_run_args() {
  RUN_ARGS=(
    run -d
    --name "${NACOS_CONTAINER_NAME}"
    --restart unless-stopped
    -p "${NACOS_SERVER_PORT}:8848"
    -p "${NACOS_CONSOLE_PORT}:8080"
    -p "${NACOS_GRPC_PORT}:9848"
    -v "${HOST_LOG_DIR}:/home/nacos/logs"
    -e MODE="${MODE}"
    -e PREFER_HOST_MODE="${PREFER_HOST_MODE}"
    -e SPRING_DATASOURCE_PLATFORM="${SPRING_DATASOURCE_PLATFORM}"
    -e MYSQL_DATABASE_NUM="${MYSQL_DATABASE_NUM}"
    -e MYSQL_SERVICE_HOST="${MYSQL_SERVICE_HOST}"
    -e MYSQL_SERVICE_PORT="${MYSQL_SERVICE_PORT}"
    -e MYSQL_SERVICE_DB_NAME="${MYSQL_SERVICE_DB_NAME}"
    -e MYSQL_SERVICE_USER="${MYSQL_SERVICE_USER}"
    -e MYSQL_SERVICE_PASSWORD="${MYSQL_SERVICE_PASSWORD}"
    -e MYSQL_SERVICE_DB_PARAM="${MYSQL_SERVICE_DB_PARAM}"
    -e JVM_XMS="${JVM_XMS}"
    -e JVM_XMX="${JVM_XMX}"
    -e JVM_XMN="${JVM_XMN}"
    -e JVM_MS="${JVM_MS}"
    -e JVM_MMS="${JVM_MMS}"
    -e NACOS_AUTH_SYSTEM_TYPE="${NACOS_AUTH_SYSTEM_TYPE}"
    -e NACOS_AUTH_ENABLE="${NACOS_AUTH_ENABLE}"
    -e NACOS_AUTH_ADMIN_ENABLE="${NACOS_AUTH_ADMIN_ENABLE}"
    -e NACOS_AUTH_CONSOLE_ENABLE="${NACOS_AUTH_CONSOLE_ENABLE}"
    -e NACOS_AUTH_TOKEN_EXPIRE_SECONDS="${NACOS_AUTH_TOKEN_EXPIRE_SECONDS}"
    -e NACOS_AUTH_TOKEN="${NACOS_AUTH_TOKEN}"
    -e NACOS_AUTH_CACHE_ENABLE="${NACOS_AUTH_CACHE_ENABLE}"
    -e NACOS_AUTH_IDENTITY_KEY="${NACOS_AUTH_IDENTITY_KEY}"
    -e NACOS_AUTH_IDENTITY_VALUE="${NACOS_AUTH_IDENTITY_VALUE}"
    "${NACOS_IMAGE}"
  )
}

print_run() {
  build_run_args
  printf 'docker'
  printf ' %q' "${RUN_ARGS[@]}"
  printf '\n'
}

start() {
  mkdir -p "${HOST_LOG_DIR}"

  if container_running; then
    echo "Nacos container is already running: ${NACOS_CONTAINER_NAME}"
    return 0
  fi

  if container_exists; then
    echo "Starting existing container: ${NACOS_CONTAINER_NAME}"
    docker start "${NACOS_CONTAINER_NAME}" >/dev/null
    return 0
  fi

  build_run_args
  docker "${RUN_ARGS[@]}" >/dev/null
  echo "Started Nacos container: ${NACOS_CONTAINER_NAME}"
}

stop() {
  if ! container_exists; then
    echo "Nacos container does not exist: ${NACOS_CONTAINER_NAME}"
    return 0
  fi
  docker stop "${NACOS_CONTAINER_NAME}"
}

restart_container() {
  if ! container_exists; then
    echo "Nacos container does not exist: ${NACOS_CONTAINER_NAME}"
    echo "Use start to create it."
    return 1
  fi
  docker restart "${NACOS_CONTAINER_NAME}"
}

recreate() {
  mkdir -p "${HOST_LOG_DIR}"

  if container_exists; then
    docker rm -f "${NACOS_CONTAINER_NAME}" >/dev/null
  fi

  build_run_args
  docker "${RUN_ARGS[@]}" >/dev/null
  echo "Recreated Nacos container: ${NACOS_CONTAINER_NAME}"
}

status() {
  docker ps -a --filter "name=^/${NACOS_CONTAINER_NAME}$"
}

logs() {
  if [[ "${FOLLOW_LOGS:-0}" == "1" ]]; then
    docker logs -f --tail=200 "${NACOS_CONTAINER_NAME}"
  else
    docker logs --tail=200 "${NACOS_CONTAINER_NAME}"
  fi
}

confirm_delete() {
  local answer
  echo "This will remove the Nacos container and local log directory:"
  echo "  ${HOST_WORK_DIR}"
  echo "It will not drop the MySQL database ${MYSQL_SERVICE_DB_NAME}."
  printf "Type YES to continue: "
  read -r answer
  if [[ "${answer}" != "YES" ]]; then
    echo "Delete cancelled."
    exit 0
  fi
}

delete_container() {
  if [[ "${SKIP_CONFIRM:-0}" != "1" ]]; then
    confirm_delete
  fi

  if container_exists; then
    docker rm -f "${NACOS_CONTAINER_NAME}" >/dev/null
    echo "Removed Nacos container: ${NACOS_CONTAINER_NAME}"
  else
    echo "Nacos container does not exist: ${NACOS_CONTAINER_NAME}"
  fi

  if [[ -d "${HOST_WORK_DIR}" ]]; then
    rm -rf "${HOST_WORK_DIR}"
    echo "Removed local Nacos directory: ${HOST_WORK_DIR}"
  else
    echo "Local Nacos directory does not exist: ${HOST_WORK_DIR}"
  fi
}

main() {
  require_docker
  load_env

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
    start)
      start
      ;;
    stop)
      stop
      ;;
    restart)
      restart_container
      ;;
    recreate)
      recreate
      ;;
    status|ps)
      status
      ;;
    logs)
      logs
      ;;
    print-run)
      print_run
      ;;
    delete|rm)
      delete_container
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
