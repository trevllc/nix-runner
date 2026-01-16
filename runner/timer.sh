#!/usr/bin/env bash
set -e

sleeptime="${1}"
fifo=$(mktemp -u)
mkfifo "${fifo}"

nohup bash -c "
while true; do
    sleep ${sleeptime}

    if [[ ! -p ${fifo} ]]; then
        break
    fi

    date +%s > ${fifo}
done
" &> /dev/null &

echo "${fifo}"