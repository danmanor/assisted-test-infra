#!/usr/bin/env bash
set -euo pipefail

# STATIC_IPS_VLAN cleanup helper. Deletes VLAN subinterfaces on libvirt bridges.
# Expected env:
#   STATIC_IPS_VLAN=(true|false) default false
#   VLAN_ID=<id> default 100

STATIC_IPS_VLAN="${STATIC_IPS_VLAN:-false}"
VLAN_ID="${VLAN_ID:-100}"

if [[ "${STATIC_IPS_VLAN}" != "true" ]]; then
  exit 0
fi

if ! command -v ip >/dev/null 2>&1; then
  echo "ip(8) not found; skipping VLAN cleanup" >&2
  exit 0
fi

# Find libvirt bridges that match our convention (ttN and sttN), best-effort
mapfile -t bridges < <(ip -o link show | awk -F': ' '{print $2}' | grep -E '^(tt|stt)[0-9]+$' || true)

for br in "${bridges[@]}"; do
  vlan_if="${br}.${VLAN_ID}"
  if ip link show dev "${vlan_if}" >/dev/null 2>&1; then
    echo "Deleting VLAN interface ${vlan_if}"
    ip link del dev "${vlan_if}" || true
  fi
done

exit 0

