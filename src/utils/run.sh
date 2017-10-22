#!/bin/bash

load_log_tool() {
    source $(which log.sh)
}


run() {
    set -o pipefail
    log_message="${1}"; shift

    log -int "${log_message}"
    log -xnt "$@"
    if "$@" 2> >(tee -a ${LOG} >&2); then
        log -dnt "${log_message}"
    else
        log -ent "${log_message}"
        log -ent "Log path: ${LOG}"
        exit 1
    fi
}

load_log_tool
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run "$@"
fi