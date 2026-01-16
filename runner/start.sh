#!/usr/bin/env bash
set -e

pids=()

cleanup () {
    for pid in "${pids[@]}"; do
        echo "Stopping ${pid}..."
        kill -TERM "${pid}"
    done
}

trap cleanup SIGTERM

echo "Starting nix daemon..."
nix-daemon &

echo "Creating nix group..."
groupadd -f nix

if [[ -d /backup ]]; then
    echo "Starting backup service..."
    /runner/backup &
    pids+=("$!")
fi

for ((i = 1; i <= $#; i++)); do
    echo "Starting runner ${i} (${!i})..."
    user="runner${i}"

    useradd -m -s /bin/bash "${user}"
    usermod -aG nix "${user}"

    cp -a /runner/. "/home/${user}/"
    chown -R "${user}" "/home/${user}/"

    mkfifo -m a=rw "/home/${user}/runner.fifo"
    runuser -u "${user}" -- /runner/run ${!i} &
    read -r pid < "/home/${user}/runner.fifo"
    pids+=("${pid}")
    rm "/home/${user}/runner.fifo"

    echo "Runner ${i} started with PID ${pid}."
done

for pid in "${pids[@]}"; do
    while [ -e "/proc/${pid}" ]; do
        sleep .6
    done
done

echo "All runners have stopped."