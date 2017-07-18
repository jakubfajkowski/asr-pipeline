#!/usr/bin/env bash

readonly MODE_DEBUG="DEBUG"
readonly MODE_ERROR="ERROR"
readonly MODE_INFO="INFO"

MODE="INFO"
NEWLINE=false

while getopts "dehin" opt; do
        case $opt in
            d)
                MODE=${MODE_DEBUG}
                ;;
            e)
                MODE=${MODE_ERROR}
                ;;
            h)
                help
                ;;
            i)
                MODE=${MODE_INFO}
                ;;
            n)
                NEWLINE=true
                ;;
            \?)
                help
                ;;
        esac
    done
    shift "$((OPTIND-1))"

readonly SCRIPT_NAME=${0}
readonly MESSAGE=${1}

main() {
    if [ ${MODE} != ${MODE_DEBUG} ] || [ "${DEBUG}" = true ] ; then
        log "${MODE}" "${MESSAGE}" "${NEWLINE}"
    fi
}

help() {
    echo "Logging tool:"
    echo -e "-d - debug log (requires: \"export DEBUG=true\")"
    echo "-e - error log"
    echo "-h - help"
    echo "-i - info log"
    echo "-n - newline at the end of message"
}

usage() {
    echo "Usage: ${SCRIPT_NAME} [-d | -e | -i] [-n] message"
    exit 1
}

log() {
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    mode=${1}
    message=${2}
    newline=${3}

    if [ ${newline} = true ] ; then
        printf "[${current_time}][${mode}] ${message}\n"
    else
        printf "[${current_time}][${mode}] ${message}"
    fi
}

main