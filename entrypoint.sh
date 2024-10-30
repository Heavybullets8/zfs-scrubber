#!/bin/sh

# entrypoint.sh
set -e

if [ -z "$ZFS_POOL" ]; then
  echo "Error: No ZFS_POOL specified. Exiting."
  exit 1
fi

echo "Starting scrub on pool: $ZFS_POOL"

if zpool scrub -w "$ZFS_POOL"; then
    echo "Scrub failed on pool: $ZFS_POOL"
    exit 1
fi

echo "Scrub completed on pool: $ZFS_POOL"
