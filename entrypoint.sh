#!/bin/bash

# entrypoint.sh
set -e

if [ -z "$ZFS_POOL" ]; then
  echo "Error: No ZFS_POOL specified. Exiting."
  exit 1
fi

if [ -z "$ACTION" ]; then
  echo "Error: No ACTION specified. Exiting."
  exit 1
fi

scrub_pool() {
  echo "===================================================="
  echo "Starting scrub on pool: $ZFS_POOL"
  echo "===================================================="

  if ! zpool scrub "$ZFS_POOL"; then
    echo "Error: Failed to start scrub on pool: $ZFS_POOL"
    exit 1
  fi

  echo "Scrub started on pool: $ZFS_POOL"
  echo "Monitoring scrub progress..."

  while true; do
    sleep 5
    status=$(zpool status "$ZFS_POOL")
    scrub_line=$(echo "$status" | grep "scan:")
    echo "$scrub_line"
    if echo "$scrub_line" | grep -q "scrub repaired"; then
      echo "===================================================="
      echo "Scrub completed on pool: $ZFS_POOL"
      echo "===================================================="
      break
    elif echo "$scrub_line" | grep -q "scrub in progress"; then
      continue
    elif echo "$scrub_line" | grep -q "resilver in progress"; then
      echo "Resilver in progress on pool: $ZFS_POOL"
      continue
    else
      echo "Error: Unexpected scrub status."
      exit 1
    fi
  done
}

cleanup_snapshots() {
  echo "===================================================="
  echo "Starting cleanup on pool: $ZFS_POOL"
  echo "===================================================="

  mapfile -t snapshots < <(zfs list -H -o name -t snapshot -r "$ZFS_POOL")

  for snapshot in "${snapshots[@]}"; do
    mapfile -t clones < <(zfs list -H -o name,origin -t filesystem,volume -r "$ZFS_POOL" | awk -v snapshot="$snapshot" '$2 == snapshot {print $1}')

    if [ "${#clones[@]}" -gt 0 ]; then
      echo "Processing snapshot with dependent clones: $snapshot"
      for clone in "${clones[@]}"; do
        echo "Promoting clone: $clone"
        if ! zfs promote "$clone"; then
          echo "Error: Failed to promote clone: $clone"
          continue
        fi
      done
      echo "Destroying snapshot: $snapshot"
      if ! zfs destroy "$snapshot"; then
        echo "Error: Failed to destroy snapshot: $snapshot"
        continue
      fi
    fi
  done

  echo "===================================================="
  echo "Cleanup completed on pool: $ZFS_POOL"
  echo "===================================================="
}

case "$ACTION" in
  scrub)
    scrub_pool
    ;;
  cleanup)
    cleanup_snapshots
    ;;
  all)
    scrub_pool
    echo
    cleanup_snapshots
    ;;
  *)
    echo "Error: Invalid ACTION specified. Use 'scrub', 'cleanup', or 'all'."
    exit 1
    ;;
esac
