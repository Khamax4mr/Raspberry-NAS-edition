#!/bin/bash

set -eu
source drive_common.sh

readonly PG_NAME="Raspberry-Drive Uninstaller"
readonly BASE_PATH="/usr/local/share/raspberry-drive"


# set values from command arguments
# $@: command arguments
_set_params() {
  while getopts "h" opt; do
    case "$opt" in
    h)  _echo_help ;;
    esac
  done
}

# print descriptions then terminate
_echo_help() {
  echo $PG_NAME
  echo "usage: sudo bash $(basename "$0")"
  echo
  exit 0
}

_main() {
  # require running with sudo/root
  if [[ "$(id -u)" -ne 0 ]]; then
    _echo_err "sudo/root required: use 'sudo bash $0'"
    exit 1
  fi

  # set variables
  _set_params "$@"

  # delete drive base
  _echo_info "removing raspberry-drive base ..."
  if [[ -e "$BASE_PATH" ]]; then
    rm -r "$BASE_PATH"
  else
    _echo_warn "no raspberry-drive base"
  fi
}

_main "$@"