#!/usr/bin/env bash
set -e

name="${1}"

cleanup () {
    echo "Removing runner ${name}..."
    kill -TERM "${pid}"

    if [[ "${name}" != *"http"* ]]; then
        config.sh remove --token "$(/runner/token "${name}")"
    fi
}

trap cleanup SIGTERM
cd || exit 1
echo "$$" > ./runner.fifo

if [[ "${name}" == *"http"* ]]; then
    act_runner register \
        --no-interactive \
        --token "${GITEA_TOKEN}" \
        --instance "${name}" \
        --name "${RUNNER_NAME:-nix}" \
        --labels "${RUNNER_LABELS:-nix}"
    act_runner daemon &
else
    config.sh \
        --replace \
        --unattended \
        --disableupdate \
        --no-default-labels \
        --token "$(/runner/token "${name}")" \
        --url "https://github.com/${name}" \
        --name "${RUNNER_NAME:-nix}" \
        --labels "${RUNNER_LABELS:-nix}"
    run.sh &
fi
pid=$!

wait "${pid}"
echo "Runner ${name} (${pid}) has finished."