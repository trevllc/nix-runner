#!/usr/bin/env bash
set -e

run () {
    cd || exit 1
    ./config.sh \
        --unattended \
        --disableupdate \
        --token "${1}" \
        --url "https://github.com/${2}" \
        --name "$(hostname)-${3}" \
        --labels nix
    ./run.sh
}

remove () {
    cd || exit 1
    ./config.sh remove \
        --token "${1}"
}

get_token () {
    if [[ -v RUNNER_REPO ]]; then
        curl -L \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${RUNNER_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/${RUNNER_REPO}/actions/runners/registration-token" | jq -r .token
    elif [[ -v RUNNER_ORG ]]; then
        curl -L \
            -X POST \
            -H "Accept: application/vnd.github+json" \
            -H "Authorization: Bearer ${RUNNER_TOKEN}" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/orgs/${RUNNER_ORG}/actions/runners/registration-token" | jq -r .token
    else
        echo "Either REPO or ORG environment variable must be set." >&2
        exit 1
    fi
}

cleanup () {
    echo "Cleaning up..."
    token="$(get_token)"
    for i in {1..5}; do
        runuser -u "runner$i" -- bash -c "$(declare -f remove); remove ${token}"
    done

    if [[ -d /backup ]]; then
        echo "Creating backup..."
        nix nario export --format 2 --all > /backup/system.nario
        echo "Backup created at /backup/system.nario"
    fi
}

if [[ ! -v RUNNER_TOKEN ]]; then
    echo "RUNNER_TOKEN environment variable must be set." >&2
    exit 1
fi

trap 'cleanup' SIGTERM

if [[ -f /backup/system.nario ]]; then
  echo "Restoring backup..."
  nix nario import --no-check-sigs < /backup/system.nario
fi

pids=()
token="$(get_token)"
for i in {1..5}; do
    useradd -m -s /bin/bash "runner$i"
    cp -a /runner/. "/home/runner$i/"
    chown -R "runner$i" "/home/runner$i/"
    runuser -u "runner$i" -- bash -c "$(declare -f run); run ${token} ${RUNNER_REPO:-$RUNNER_ORG} ${i}" &
    pids+=("$!")
done

for pid in "${pids[@]}"; do
  wait "$pid"
  # Capture the exit status of the process that just finished
  exit_status=$? 

  if [ $exit_status -ne 0 ]; then
    echo "Process $pid failed with exit code $exit_status"
  else
    echo "Process $pid completed successfully"
  fi
done

echo "All runners have completed."
cleanup