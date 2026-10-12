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

failed=0

# Iterate sources
for SOURCE in "${!SOURCES[@]}"; do
    echo "Doing ${SOURCE} from ${SOURCES[$SOURCE]}"

    # Rsync the content
    if /usr/bin/rsync -a --delete \
        "${SOURCES[$SOURCE]}" \
        "${TARGET}/${SOURCE}/"
    then
        # RC 0 is success
        /usr/bin/echo "$(/usr/bin/date -Iseconds) Ok" \
            > "${TARGET}/${SOURCE}/.backup"
    else
        rc=$?
        # RC 24 is "Partial transfer due to vanished source files"
        if [ "${rc}" -eq 24 ]; then
            /usr/bin/echo "$(/usr/bin/date -Iseconds) Ok" \
                > "${TARGET}/${SOURCE}/.backup"
        else

            ((++failed))
            # Try to add an error file to the target, but don't fail if that fails
            # The if protects against the script failing if the echo command fails (e.g. if the target is read-only)
            if /usr/bin/echo "$(/usr/bin/date -Iseconds) Failed rc=${rc}" \
                > "${TARGET}/${SOURCE}/.backup.error"
            then
                /usr/bin/echo "Error file created for ${SOURCE}"
            fi
            /usr/bin/echo \
                "ERROR: rsync failed for ${SOURCE} (rc=${rc})" >&2
        fi
    fi
done

if [ "${failed}" -gt 0 ]; then
    echo "ERROR: ${failed} source(s) failed to backup"
    exit 1
else
    echo "All sources backed up successfully."
fi
