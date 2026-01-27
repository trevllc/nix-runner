#!/usr/bin/env bash
set -e

backup () {
    echo "Creating backup..."
    ts=$(date +%s)
    nix nario export --format 2 --all > "/backup/${ts}.nario"
    echo "Backup created at /backup/${ts}.nario"
}

clean () {
    while [ "$(find . | wc -l)" -gt 2 ]; do
        oldest=$(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n | head -1)
        echo "Removing oldest backup: ${oldest}"
        rm -f "${oldest}"
    done
}

cd /backup || exit 1

mapfile -t backups < <(find . -maxdepth 1 -name "*.nario" -printf "%f\n" | sort -t. -k1 -n)
for backup in "${backups[@]}"; do
    echo "Attempting to restore backup ${backup}..."
    if nix nario import --no-check-sigs < "${backup}"; then
        echo "Backup successfully restored."
        break
    else
        rm -f "${backup}"
        echo "Failed to restore backup ${backup}, removed corrupted file."
    fi
done

clean

while true; do
    sleep 10m
    backup
    clean
done