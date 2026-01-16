#!/usr/bin/env bash
set -e

backup () {
    echo "Creating backup..."
    ts=$(date +%s)
    nix nario export --format 2 --all > "/backup/${ts}.nario"
    echo "Backup created at /backup/${ts}.nario"
}

clean () {
    while [ "$(find . | wc -l)" -gt 5 ]; do
        oldest=$(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n | head -1)
        echo "Removing oldest backup: ${oldest}"
        rm -f "${oldest}"
    done
}

cleanup () {
    echo "Shutting down backup service..."
    backup
    echo "exit" > "${timer}"
    wait "${pid}"
}

trap cleanup SIGTERM
cd /backup || exit 1
timer=$(/runner/timer 10m)

mapfile -t backups < <(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n)
for backup in "${backups[@]}"; do
    echo "Attempting to restore backup ${backup}..."
    if nix nario import --no-check-sigs < "${backup}"; then
        echo "Backup successfully restored."
        break
    fi
done

clean

while true; do
    if read -r tick < "${timer}"; then
        if [[ "${tick}" == "exit" ]]; then
            rm -f "${timer}"
            break
        fi

        backup
        clean
    fi
done &
pid=$!

wait "${pid}"