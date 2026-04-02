#!/usr/bin/env bash

SSH_CONFIG="${SSH_CONFIG:-$HOME/.ssh/config}"
GREEN=$'\033[32m'
RED=$'\033[31m'
ORANGE=$'\033[33m'
RESET=$'\033[0m'

if [ ! -f "$SSH_CONFIG" ]; then
  echo "ssh config not found: $SSH_CONFIG" >&2
  exit 1
fi

printf '%-35s %-35s %-12s %s\n' "HOST" "HOSTNAME" "VIA" "STATUS"

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
$(ssh -G "$host" 2>/dev/null)
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

  printf '%-35s %-35s %-12s %b%s%b\n' "$host" "$hostname" "$via" "$color" "$status" "$RESET"
done
