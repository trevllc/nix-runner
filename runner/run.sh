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

URL=$(echo "${name}" | jc --url)
hostname=$(echo "${URL}" | jq -r '.hostname')
scheme=$(echo "${URL}" | jq -r '.scheme // "https"')
path=$(echo "${URL}" | jq -r '.path // empty')

# validate hostname
if [[ -z "${hostname}" || "${hostname}" == "null" ]]; then
    echo "No hostname found: ${name}"
    exit 1
fi

# detect runner type
if [[ "${hostname}" == "github.com" ]]; then
    runner_type="github"
else
    VERSION=$(curl -s "${scheme}://${hostname}/api/v1/version" | jq -r .version || echo "")
    if [[ -n "${VERSION}" && "${VERSION}" == *"gitea"* ]]; then
        echo "Detected Forgejo instance."
        runner_type="forgejo"
    elif [[ -n "${VERSION}" ]]; then
        echo "Detected Gitea instance."
        runner_type="gitea"
    else
        echo "Assuming GitHub instance."
        runner_type="github"
    fi
fi

echo "Starting runner ${scheme}://${hostname}${path}"

if [[ "${runner_type}" == "gitea" ]]; then
    act_runner register \
        --no-interactive \
        --token "${GITEA_TOKEN}" \
        --instance "${scheme}://${hostname}${path}" \
        --name "${RUNNER_NAME:-nix}" \
        --labels "${RUNNER_LABELS:-nix}"
    act_runner daemon &
elif [[ "${runner_type}" == "forgejo" ]]; then
    forgejo-runner register \
        --no-interactive \
        --token "${FORGEJO_TOKEN}" \
        --instance "${scheme}://${hostname}${path}" \
        --name "${RUNNER_NAME:-nix}" \
        --labels "${RUNNER_LABELS:-nix}"
    forgejo-runner daemon &
else
    config.sh \
        --replace \
        --unattended \
        --disableupdate \
        --no-default-labels \
        --token "$(/runner/token "${path:1}")" \
        --url "${scheme}://${hostname}${path}" \
        --name "${RUNNER_NAME:-nix}" \
        --labels "${RUNNER_LABELS:-nix}"
    run.sh &
fi
pid=$!

wait "${pid}"
echo "Runner ${name} (${pid}) has finished."