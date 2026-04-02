#!/usr/bin/env bash

SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
GREEN=$'\033[32m'
RED=$'\033[31m'
ORANGE=$'\033[33m'
RESET=$'\033[0m'
ROWS_FILE="$(mktemp -t ssh-graveyard.XXXXXX)"

cleanup() {
  rm -f "$ROWS_FILE"
}

trim_field() {
  local value="$1"
  local width="$2"
  local value_len="${#value}"

  if [ "$value_len" -le "$width" ]; then
    printf '%s' "$value"
    return
  fi

  if [ "$width" -le 3 ]; then
    printf '%.*s' "$width" "$value"
    return
  fi

  printf '%.*s...' "$((width - 3))" "$value"
}

if [ ! -f "$SSH_CONFIG" ]; then
  echo "ssh config not found: $SSH_CONFIG" >&2
  exit 1
fi

trap cleanup EXIT

awk '
/^[[:space:]]*Host[[:space:]]+/ {
  for (i = 2; i <= NF; i++) {
    print $i
  }
}
' "$SSH_CONFIG" | while IFS= read -r host; do
  case "$host" in
    "" | "!"* | *"*"* | *"?"*)
      continue
      ;;
  esac

  hostname=""
  via="direct"

  while IFS= read -r line; do
    case "$line" in
      hostname\ *)
        hostname=${line#hostname }
        ;;
      proxyjump\ *)
        via="proxyjump"
        ;;
      proxycommand\ *)
        if [ "$via" = "direct" ]; then
          via="proxycommand"
        fi
        ;;
    esac
  done <<EOF
$(ssh -F "$SSH_CONFIG" -G "$host" 2>/dev/null)
EOF

  if [ -z "$hostname" ]; then
    hostname="$host"
  fi

  if ping -o -c 1 -t 2 "$hostname" >/dev/null 2>&1; then
    status="alive"
  else
    status="unreachable"
  fi

  if [ "$status" = "alive" ]; then
    color="$GREEN"
  elif [ "$status" = "unreachable" ]; then
    color="$RED"
  else
    color="$ORANGE"
  fi

  printf '%s\t%s\t%s\t%s\t%s\n' "$host" "$hostname" "$via" "$status" "$color" >>"$ROWS_FILE"
done

max_host_len=4
max_hostname_len=8
max_via_len=3
max_status_len=6

while IFS=$'\t' read -r host hostname via status color; do
  if [ "${#host}" -gt "$max_host_len" ]; then
    max_host_len=${#host}
  fi

  if [ "${#hostname}" -gt "$max_hostname_len" ]; then
    max_hostname_len=${#hostname}
  fi

  if [ "${#via}" -gt "$max_via_len" ]; then
    max_via_len=${#via}
  fi

  if [ "${#status}" -gt "$max_status_len" ]; then
    max_status_len=${#status}
  fi
done <"$ROWS_FILE"

TERM_WIDTH="${COLUMNS:-$(tput cols 2>/dev/null || echo 100)}"
case "$TERM_WIDTH" in
  ''|*[!0-9]*)
    TERM_WIDTH=100
    ;;
esac

host_width="$max_host_len"
hostname_width="$max_hostname_len"
via_width="$max_via_len"
status_width="$max_status_len"

if [ "$host_width" -gt 24 ]; then
  host_width=24
fi

if [ "$hostname_width" -gt 28 ]; then
  hostname_width=28
fi

TOTAL_WIDTH=$((host_width + hostname_width + via_width + status_width + 6))

if [ "$TOTAL_WIDTH" -gt "$TERM_WIDTH" ] && [ "$hostname_width" -gt 18 ]; then
  reduction=$((TOTAL_WIDTH - TERM_WIDTH))
  capacity=$((hostname_width - 18))
  if [ "$reduction" -gt "$capacity" ]; then
    reduction="$capacity"
  fi
  hostname_width=$((hostname_width - reduction))
  TOTAL_WIDTH=$((TOTAL_WIDTH - reduction))
fi

if [ "$TOTAL_WIDTH" -gt "$TERM_WIDTH" ] && [ "$host_width" -gt 12 ]; then
  reduction=$((TOTAL_WIDTH - TERM_WIDTH))
  capacity=$((host_width - 12))
  if [ "$reduction" -gt "$capacity" ]; then
    reduction="$capacity"
  fi
  host_width=$((host_width - reduction))
fi

printf '%-*s  %-*s  %-*s  %-*s\n' \
  "$host_width" "HOST" \
  "$hostname_width" "HOSTNAME" \
  "$via_width" "VIA" \
  "$status_width" "STATUS"

while IFS=$'\t' read -r host hostname via status color; do
  host_display="$(trim_field "$host" "$host_width")"
  hostname_display="$(trim_field "$hostname" "$hostname_width")"
  printf '%-*s  %-*s  %-*s  %b%-*s%b\n' \
    "$host_width" "$host_display" \
    "$hostname_width" "$hostname_display" \
    "$via_width" "$via" \
    "$color" "$status_width" "$status" "$RESET"
done <"$ROWS_FILE"
