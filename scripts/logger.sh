#!/usr/bin/env bash

readonly MODE_DEBUG="[DEBUG]"
readonly MODE_ERROR="[ERROR]"
readonly MODE_INFO="[INFO]"

TIMESTAMP=""
MODE=""
NEWLINE=""

while getopts "dehint" opt; do
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
                NEWLINE="\n"
                ;;
            t)
                TIMESTAMP="[$(date '+%Y-%m-%d %H:%M:%S')]"
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
    if [ "${MODE}" != ${MODE_DEBUG} ] || [ "${DEBUG}" = true ] ; then
        log "${TIMESTAMP}" "${MODE}" "${MESSAGE}" "${NEWLINE}"
    fi
}

help() {
    echo "Logging tool:"
    echo -e "-d - debug log (requires: \"export DEBUG=true\")"
    echo "-e - error log"
    echo "-h - help"
    echo "-i - info log"
    echo "-n - newline at the end of message"
    echo "-t - timestamp at the beginning"
}

usage() {
    echo "Usage: ${SCRIPT_NAME} [-d | -e | -i] [-n] message"
    exit 1
}

log() {
    timestamp=${1}
    mode=${2}
    message=${3}
    newline=${4}

    if [ "${TIMESTAMP}" != "" ] || [ "${MODE}" != "" ] ; then
        printf "${timestamp}${mode}\t${message}${newline}"
    else
        printf "${message}${newline}"
    fi
}

main