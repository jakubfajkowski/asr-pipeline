#!/usr/bin/env bash

readonly SCRIPT_NAME=$(basename ${0})

readonly MODE_DEBUG="[DEBUG]"
readonly MODE_ERROR="[ERROR]"
readonly MODE_INFO="[INFO]"

TIMESTAMP=""
MODE=""
NEWLINE=""

help() {
    echo "Logging tool:"
    echo -e "-d - debug log (requires: \"export DEBUG=true\")"
    echo "-e - error log"
    echo "-h - help"
    echo "-i - info log"
    echo "-n - newline at the end of message"
    echo "-t - timestamp at the beginning"
    exit 1
}

usage() {
    echo "Usage: ${SCRIPT_NAME} [-d | -e | -i] [-nt] message"
    echo "Example: ${SCRIPT_NAME} -int \"Hello world!\""
    exit 1
}

while getopts "dehintu" opt; do
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
            u)
                usage
                ;;
            \?)
                help
                ;;
        esac
    done
    shift "$((OPTIND-1))"

readonly MESSAGE=${1}

main() {
    if [ "${MODE}" != ${MODE_DEBUG} ] || [ "${DEBUG}" = true ] ; then
        log "${TIMESTAMP}" "${MODE}" "${MESSAGE}" "${NEWLINE}"
    fi
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