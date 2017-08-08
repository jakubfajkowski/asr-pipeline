#!/usr/bin/env bash

readonly SCRIPT_NAME=$(basename ${0})

readonly MODE_DEBUG="[DEBUG]    "
readonly MODE_DONE="[DONE]    "
readonly MODE_ERROR="[ERROR]    "
readonly MODE_INFO="[INFO]    "
readonly MODE_WARNING="[WARNING]    "

readonly COLOR_DEBUG="\e[35m"
readonly COLOR_DONE="\e[32m"
readonly COLOR_ERROR="\e[31m"
readonly COLOR_INFO="\e[34m"
readonly COLOR_WARNING="\e[33m"

readonly COLOR_DEFAULT="\e[0m"


main() {
    log "$@"
}

log() {
    local timestamp=""
    local mode=""
    local newline=""
    local color_begin=""
    local color_end=""

    local OPTIND
    while getopts "dehintuwx" opt; do
        case $opt in
            d)
                mode=${MODE_DONE}
                color_begin=${COLOR_DONE}
                color_end=${COLOR_DEFAULT}
                ;;
            e)
                mode=${MODE_ERROR}
                color_begin=${COLOR_ERROR}
                color_end=${COLOR_DEFAULT}
                ;;
            h)
                print_help
                ;;
            i)
                mode=${MODE_INFO}
                color_begin=${COLOR_INFO}
                color_end=${COLOR_DEFAULT}
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
                color_begin=${COLOR_WARNING}
                color_end=${COLOR_DEFAULT}
                ;;
            x)
                mode=${MODE_DEBUG}
                color_begin=${COLOR_DEBUG}
                color_end=${COLOR_DEFAULT}
                ;;
            \?)
                print_help
                ;;
        esac
    done
    shift "$((OPTIND-1))"

    local message="$@"

    if [ "${mode}" != "${MODE_DEBUG}" ] || [ "${DEBUG}" == true ] ; then
        printf "${color_begin}${timestamp}${mode}${message}${color_end}${newline}" 1>&2
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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi