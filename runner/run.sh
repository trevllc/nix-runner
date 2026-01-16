#!/usr/bin/env bash
set -e

name="${1}"

cleanup () {
    echo "Removing runner ${name}..."
    kill -TERM "${pid}"
    ./config.sh remove --token "$(/runner/token "${name}")"
}

trap cleanup SIGTERM
cd || exit 1
echo "$$" > ./runner.fifo

./config.sh \
    --replace \
    --unattended \
    --disableupdate \
    --token "$(/runner/token "${name}")" \
    --url "https://github.com/${name}" \
    --name "${RUNNER_NAME:-nix}" \
    --labels "${RUNNER_LABELS:-nix}"

./run.sh &
pid=$!

wait "${pid}"
echo "Runner ${name} (${pid}) has finished."