#!/usr/bin/env bash
set -e

backup () {
    echo "Creating backup..."
    ts=$(date +%s)
    nix nario export --format 2 --all > "/backup/${ts}.nario"
    echo "Backup created at /backup/${ts}.nario"
}

cleanup () {
    echo "Shutting down backup service..."
    echo "exit" > "${timer}"
}

trap cleanup SIGTERM
cd /backup || exit 1
timer=$(/runner/timer 10m)

newest=$(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n | tail -1)
if [[ -f "${newest}" ]]; then
    echo "Restoring from latest backup: ${newest}..."
    if nix nario import --no-check-sigs < "${newest}"; then
        echo "Restore complete."
    else
        echo "Restore failed."
    fi
fi

echo "Waiting for backup ticks..."
while true; do
    if read -r tick < "${timer}"; then
        backup

        if [[ "${tick}" == "exit" ]]; then
            rm -f "${timer}"
            break
        fi

        while [ "$(find . | wc -l)" -gt 5 ]; do
            oldest=$(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n | head -1)
            echo "Removing oldest backup: ${oldest}"
            rm -f "${oldest}"
        done
    fi
done &
wait "$!"

echo "Backup service has shut down."