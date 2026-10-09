#!/usr/bin/env bash

set -euo pipefail

TARGET="/mnt/truenas-k3s/backup"

# Sanity check: zorg dat de NFS mount aanwezig is
if ! mountpoint -q /mnt/truenas-k3s; then
  echo "ERROR: backup target is niet gemount" >&2
  exit 1
fi

me="$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")"
echo "Ik ben $me"

declare -A SOURCES=(
  ["etc"]="/etc/"
  ["pvcs"]="/var/lib/rancher/k3s/storage/"
  ["homes"]="/home/"
)

#
# Databases worden niet door dit script gedumpt.
#
# Voor database workloads (MySQL, MariaDB, PostgreSQL, etc.)
# wordt aanbevolen een aparte backup-PVC te gebruiken.
#
# Een Kubernetes CronJob maakt periodiek consistente dumps
# naar die PVC. Dit script backupt vervolgens alleen de PVC's
# op bestandsniveau.
#

for SOURCE in "${!SOURCES[@]}"; do
  echo "Doing ${SOURCE} from ${SOURCES[$SOURCE]}"

  /usr/bin/rsync -a --delete \
    "${SOURCES[$SOURCE]}" \
    "${TARGET}/${SOURCE}/"
done

echo "Backup completed successfully."
