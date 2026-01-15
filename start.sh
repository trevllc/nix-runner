#!/usr/bin/env bash
set -euo pipefail

get_token () {
    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${REPO}/actions/runners/registration-token" | jq -r .token
}

cleanup () {
    echo "Cleaning up..."
    ./config.sh remove --token "$(get_token)"

    if [[ -d /backup ]]; then
        echo "Creating backup..."
        nix nario export --format 2 --all > /backup/system.nario
    fi

    echo "Uninstalling Nix..."
    /nix/nix-installer uninstall --no-confirm
}

trap 'cleanup' SIGTERM

if [[ -f /backup/system.nario ]]; then
  echo "Restoring backup..."
  nix nario import --no-check-sigs < /backup/system.nario
fi

./config.sh --url "https://github.com/${REPO}" --token "$(get_token)" --labels nix
./run.sh &
wait $!

cleanup