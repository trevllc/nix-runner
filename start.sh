#!/usr/bin/env bash
set -e

get_token () {
    if [[ -v REPO ]]; then
        curl -L \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/${REPO}/actions/runners/registration-token" | jq -r .token
    elif [[ -v ORG ]]; then
        curl -L \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/orgs/${ORG}/actions/runners/registration-token" | jq -r .token
    else
        echo "Either REPO or ORG environment variable must be set." >&2
        exit 1
    fi
}

cleanup () {
    echo "Cleaning up..."
    ./config.sh remove --token "$(get_token)"

    if [[ -d /backup ]]; then
        echo "Creating backup..."
        nix nario export --format 2 --all > /backup/system.nario
        echo "Backup created at /backup/system.nario"
    fi
}

if [[ ! -v TOKEN ]]; then
    echo "TOKEN environment variable must be set." >&2
    exit 1
fi

trap 'cleanup' SIGTERM

if [[ -f /backup/system.nario ]]; then
  echo "Restoring backup..."
  nix nario import --no-check-sigs < /backup/system.nario
fi

./config.sh --unattended --disableupdate --url "https://github.com/${REPO:-$ORG}" --token "$(get_token)" --labels nix
./run.sh &
wait $!

cleanup