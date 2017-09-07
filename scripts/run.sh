#!/bin/bash

run() {
    log_message="${1}"; shift

    log -int "${log_message}"
    log -xnt "$@"
    if "$@" 2> ${ERROR_LOG}; then
        log -dnt "${log_message}"
    else
        log -ent "${log_message}"
        log -ent "Log path: ${ERROR_LOG}"
        exit 1
    fi
}

load_log_tool() {
    source $(which log.sh)
}

load_log_tool
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run "$@"
fi