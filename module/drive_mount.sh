#!/bin/bash

RUN_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

set -eu
source "$RUN_PATH/drive_common.sh"

readonly PG_NAME="Raspberry-Drive Mount Module"
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
  
  # prevent double mount
  if [[ $(echo $info | jq -r '.mountpoint') != 'null' ]]; then
    _echo_err "$DEV_NAME is already mounted"
    exit 1
  fi

  # prevent unavailable uuid
  local uuid="$(echo $info | jq -r '.uuid')"
  if [[ "$uuid" == 'null' ]]; then
    _echo_err "no uuid of $DEV_NAME"
    exit 1
  fi

  # device mount
  if [[ -e "$BASE_PATH/$uuid" ]]; then
    _echo_warn "$DEV_NAME mount path already exist"
  else
    mkdir "$BASE_PATH/$uuid"
    chmod 750 "$BASE_PATH/$uuid"
  fi
  _echo_info "mounting device ..."
  mount "/dev/$DEV_NAME" "$BASE_PATH/$uuid"

  # create umount script
  _echo_info "creating unmount script ..."
  printf "%s" "bash ./module/drive_umount.sh -d $DEV_NAME" > "$BASE_PATH/umount_$uuid.sh"
  chmod 750 "$BASE_PATH/umount_$uuid.sh"
}

_main "$@"