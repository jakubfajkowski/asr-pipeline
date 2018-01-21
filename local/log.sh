#!/bin/bash
# =======================
# === LOGGING UTILITY ===
# =======================

readonly MODE_DEBUG="[DEBUG]    "
readonly MODE_DONE="[DONE]    "
readonly MODE_ERROR="[ERROR]    "
readonly MODE_INFO="[INFO]    "
readonly MODE_WARNING="[WARNING]    "

readonly COLOR_DEFAULT="\e[0m"
readonly COLOR_DEBUG="\e[35m"
readonly COLOR_DONE="\e[32m"
readonly COLOR_ERROR="\e[31m"
readonly COLOR_INFO="\e[34m"
readonly COLOR_WARNING="\e[33m"

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
            i)
                mode=${MODE_INFO}
                color_begin=${COLOR_INFO}
                color_end=${COLOR_DEFAULT}
                ;;
            n)
                newline="\n"
                ;;
            t)
                timestamp="[$(date '+%Y-%m-%d %H:%M:%S,%3N')]"
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
        esac
    done
    shift "$((OPTIND-1))"

    local message="$@"

    if [ "${mode}" != "${MODE_DEBUG}" ] || [ "${DEBUG}" == true ] ; then
        printf "${color_begin}${timestamp}${mode}${message}${color_end}${newline}" 1>&2
    fi
}

log $@