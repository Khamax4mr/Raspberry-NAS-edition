#!/bin/bash

RUN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -eu
source "$RUN_PATH/drive_common.sh"

readonly PG_NAME="Raspberry-Drive Unmount Module"
readonly BASE_PATH="/usr/local/share/raspberry-drive"

DEV_NAME=""


# set values from command arguments
# $@: command arguments
_set_params() {
  while getopts "d:h" opt; do
    case "$opt" in
    d)  if [[ "$OPTARG" == -* ]]; then
          _echo_err "invalid -d input, no such operend: $OPTARG"
          exit 1
        fi
        DEV_NAME="$OPTARG" ;;
    h)  _echo_help ;;
    esac
  done
}

# print descriptions then terminate
_echo_help() {
  echo $PG_NAME
  echo "usage: bash $(basename "$0") [-d <name>]"
  echo
  echo "description:"
  printf "  -d <name>,\t device name\n"
  echo
  exit 0
}

# get device type, mountpoint, uuid
# $1: device name
_get_disk_info() {
  printf "$(lsblk -Jfo NAME,TYPE,MOUNTPOINT,UUID | jq '.blockdevices[] | select(.name=="'$1'")')"
}

_main() {
  # require running with sudo/root
  if [[ "$(id -u)" -ne 0 ]]; then
    _echo_err "sudo/root required: use 'sudo bash $0'"
    exit 1
  fi

  # prevent unavailable device path
  _set_params "$@"
  if [[ ! -e "/dev/$DEV_NAME" ]]; then
    _echo_err "no device path of $DEV_NAME"
    exit 1
  fi

  # prevent non-disk device
  local info="$(_get_disk_info "$DEV_NAME")"
  if [[ $(echo $info | jq -r '.type') != 'disk' ]]; then
    _echo_err "no disk $DEV_NAME"
    exit 1
  fi
  
  # unmount device
  _echo_info "unmounting device ..."
  if [[ $(echo $info | jq -r '.mountpoint') == 'null' ]]; then
    _echo_warn "$DEV_NAME is already unmounted"
  else
    umount "/dev/$DEV_NAME"
  fi

  # remove mountpoint
  _echo_info "removing mountpoint ..."
  local uuid="$(echo $info | jq -r '.uuid')"
  if [[ "$uuid" == 'null' ]]; then
    _echo_warn "no uuid of $DEV_NAME"
  else
    if [[ -e "$BASE_PATH/$uuid" ]]; then
      rmdir "$BASE_PATH/$uuid"
    fi
  fi
}

_main "$@"