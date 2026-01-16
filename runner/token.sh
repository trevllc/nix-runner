#!/usr/bin/env bash
set -e

if [[ "${1}" == *"/"* && -v REPO_TOKEN ]]; then
    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${REPO_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/${1}/actions/runners/registration-token" | jq -r .token
elif [[ -v ORG_TOKEN ]]; then
    curl -L \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${ORG_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/orgs/${1}/actions/runners/registration-token" | jq -r .token
else
    echo "ORG_TOKEN or REPO_TOKEN must be set." >&2
    exit 1
fi