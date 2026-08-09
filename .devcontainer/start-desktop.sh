#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DISPLAY_NUMBER="${DISPLAY_NUMBER:-1}"
export DISPLAY=":${DISPLAY_NUMBER}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-${UID}}"

GEOMETRY="${VNC_GEOMETRY:-1440x900}"
DEPTH="${VNC_DEPTH:-24}"
VNC_PORT="${VNC_PORT:-5901}"
NOVNC_PORT="${NOVNC_PORT:-6080}"

CONFIG_DIR="${HOME}/.config/hokadiw-desktop"
STATE_DIR="${HOME}/.local/state/hokadiw-desktop"
PASSWORD_FILE="${CONFIG_DIR}/vnc.passwd"
PASSWORD_TEXT_FILE="${CONFIG_DIR}/password.txt"

mkdir -p "${CONFIG_DIR}" "${STATE_DIR}" "${XDG_RUNTIME_DIR}"
chmod 700 "${CONFIG_DIR}" "${STATE_DIR}" "${XDG_RUNTIME_DIR}"

pid_is_running() {
  local pid_file="$1"
  [[ -s "${pid_file}" ]] && kill -0 "$(<"${pid_file}")" 2>/dev/null
}

stop_process() {
  local name="$1"
  local pid_file="${STATE_DIR}/${name}.pid"

  if pid_is_running "${pid_file}"; then
    kill "$(<"${pid_file}")" 2>/dev/null || true
  fi
  rm -f "${pid_file}"
}

stop_desktop() {
  stop_process websockify
  stop_process x11vnc
  stop_process xfce
  stop_process xvfb
  rm -f "/tmp/.X${DISPLAY_NUMBER}-lock" 2>/dev/null || true
  rm -f "/tmp/.X11-unix/X${DISPLAY_NUMBER}" 2>/dev/null || true
}

case "${1:-start}" in
  stop)
    stop_desktop
    echo "Ubuntu Desktop stopped."
    exit 0
    ;;
  restart|--restart)
    stop_desktop
    ;;
  start|status)
    ;;
  *)
    echo "Usage: $0 [start|stop|restart|status]" >&2
    exit 2
    ;;
esac

if [[ ! -s "${PASSWORD_FILE}" ]]; then
  VNC_PASSWORD="${VNC_PASSWORD:-$(openssl rand -hex 4)}"
  x11vnc -storepasswd "${VNC_PASSWORD}" "${PASSWORD_FILE}" >/dev/null
  printf '%s\n' "${VNC_PASSWORD}" >"${PASSWORD_TEXT_FILE}"
  chmod 600 "${PASSWORD_FILE}" "${PASSWORD_TEXT_FILE}"
fi

if [[ "${1:-start}" == "status" ]]; then
  for service in xvfb xfce x11vnc websockify; do
    if pid_is_running "${STATE_DIR}/${service}.pid"; then
      printf '%-10s running (PID %s)\n' "${service}" "$(<"${STATE_DIR}/${service}.pid")"
    else
      printf '%-10s stopped\n' "${service}"
    fi
  done
  echo "VNC password: $(<"${PASSWORD_TEXT_FILE}")"
  exit 0
fi

if ! pid_is_running "${STATE_DIR}/xvfb.pid"; then
  # A container restart can leave stale X11 lock files behind.
  rm -f "/tmp/.X${DISPLAY_NUMBER}-lock" 2>/dev/null || true
  rm -f "/tmp/.X11-unix/X${DISPLAY_NUMBER}" 2>/dev/null || true

  nohup Xvfb "${DISPLAY}" \
    -screen 0 "${GEOMETRY}x${DEPTH}" \
    -nolisten tcp \
    -ac \
    +extension GLX \
    +render \
    -noreset \
    >"${STATE_DIR}/xvfb.log" 2>&1 &
  echo "$!" >"${STATE_DIR}/xvfb.pid"
fi

for _ in $(seq 1 30); do
  if xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

if ! xdpyinfo -display "${DISPLAY}" >/dev/null 2>&1; then
  echo "Xvfb did not start. See ${STATE_DIR}/xvfb.log" >&2
  exit 1
fi

if ! pid_is_running "${STATE_DIR}/xfce.pid"; then
  nohup bash "${SCRIPT_DIR}/xfce-session.sh" \
    >"${STATE_DIR}/xfce.log" 2>&1 &
  echo "$!" >"${STATE_DIR}/xfce.pid"
fi

if ! pid_is_running "${STATE_DIR}/x11vnc.pid"; then
  nohup x11vnc \
    -display "${DISPLAY}" \
    -rfbport "${VNC_PORT}" \
    -localhost \
    -forever \
    -shared \
    -rfbauth "${PASSWORD_FILE}" \
    -noxdamage \
    -repeat \
    >"${STATE_DIR}/x11vnc.log" 2>&1 &
  echo "$!" >"${STATE_DIR}/x11vnc.pid"
fi

if ! pid_is_running "${STATE_DIR}/websockify.pid"; then
  nohup websockify \
    --web=/usr/share/novnc \
    "${NOVNC_PORT}" \
    "localhost:${VNC_PORT}" \
    >"${STATE_DIR}/websockify.log" 2>&1 &
  echo "$!" >"${STATE_DIR}/websockify.pid"
fi

sleep 1

echo "Ubuntu Desktop is running."
echo "Open the forwarded port ${NOVNC_PORT} and keep it Private."
echo "VNC password: $(<"${PASSWORD_TEXT_FILE}")"
echo "Status command: bash .devcontainer/start-desktop.sh status"
