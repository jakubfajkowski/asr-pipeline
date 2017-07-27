#!/usr/bin/env bash

readonly SCRIPT_NAME=$(basename ${0})

readonly MODE_DEBUG="[DEBUG]"
readonly MODE_ERROR="[ERROR]"
readonly MODE_INFO="[INFO]"
readonly MODE_WARNING="[WARNING]"


main() {
    log "$@"
}

log() {
    local timestamp=""
    local mode=""
    local newline=""

    local OPTIND
    while getopts "dehintuw" opt; do
        case $opt in
            d)
                mode=${MODE_DEBUG}
                ;;
            e)
                mode=${MODE_ERROR}
                ;;
            h)
                print_help
                ;;
            i)
                mode=${MODE_INFO}
                ;;
            n)
                newline="\n"
                ;;
            t)
                timestamp="[$(date '+%Y-%m-%d %H:%M:%S')]"
                ;;
            u)
                print_usage
                ;;
            w)
                mode=${MODE_WARNING}
                ;;
            \?)
                print_help
                ;;
        esac
    done
    shift "$((OPTIND-1))"

    local message="$@"

    if [ "${mode}" != ${MODE_DEBUG} ] || [ "${DEBUG}" = true ] ; then
        print_log "${timestamp}" "${mode}" "${message}" "${newline}"
    fi
}

print_help() {
    echo "Logging tool:"
    echo -e "-d - debug log (requires: \"export DEBUG=true\")"
    echo "-e - error log"
    echo "-h - help"
    echo "-i - info log"
    echo "-n - newline at the end of message"
    echo "-t - timestamp at the beginning"
    echo "-w - warning log"
    exit 1
}

print_usage() {
    echo "Usage: ${SCRIPT_NAME} [-d | -e | -i] [-nt] message"
    echo "Example: ${SCRIPT_NAME} -int \"Hello world!\""
    exit 1
}

print_log() {
    local timestamp=${1}
    local mode=${2}
    local message=${3}
    local newline=${4}

    if [ "${timestamp}" != "" ] || [ "${mode}" != "" ] ; then
        if [ "${mode}" == ${MODE_ERROR} ] ; then
            printf "${timestamp}${mode}\t${message}${newline}" 1>&2
        else
            printf "${timestamp}${mode}\t${message}${newline}"
        fi
    else
        printf "${message}${newline}"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi