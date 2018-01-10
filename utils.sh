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

# ============================
# === REQUIREMENTS UTILITY ===
# ============================

requirements() {
    for file in $@; do
        if [ ! -f ${file} ]; then
            log -ent "File ${file} is required!"
            exit 1
        fi
    done
}

# =======================
# === EXECUTE UTILITY ===
# =======================

execute() {
    set -o pipefail
    log_message="${1}"; shift

    log -int "${log_message}"
    log -xnt "$@"
    if "$@" 2> >(tee -a build.log >&2); then
        log -dnt "${log_message}"
    else
        log -ent "${log_message}"
        log -ent "Log path: build.log"
        exit 1
    fi
}

# =========================
# === ARGUMENTS UTILITY ===
# =========================

OPTIONAL_ARGUMENTS_NAMES=()
OPTIONAL_ARGUMENTS_STORE_VARIABLES=()
OPTIONAL_ARGUMENTS_DEFAULT_VALUES=()
OPTIONAL_ARGUMENTS_HELP_MESSAGES=()

POSITIONAL_ARGUMENTS_STORE_VARIABLES=()
POSITIONAL_ARGUMENTS_HELP_MESSAGES=()

register_optional_argument() {
    name=${1}
    store_variable=${2}
    default_value=${3}
    help_message=${4}

    OPTIONAL_ARGUMENTS_NAMES+=("${name}")
    OPTIONAL_ARGUMENTS_STORE_VARIABLES+=("${store_variable}")
    OPTIONAL_ARGUMENTS_DEFAULT_VALUES+=("${default_value}")
    OPTIONAL_ARGUMENTS_HELP_MESSAGES+=("${help_message}")
}

register_positional_argument() {
    store_variable=${1}
    help_message=${2}

    POSITIONAL_ARGUMENTS_STORE_VARIABLES+=("${store_variable}")
    POSITIONAL_ARGUMENTS_HELP_MESSAGES+=("${help_message}")
}

print_arguments_help_message() {
    echo "Optional arguments:"
    for i in ${!OPTIONAL_ARGUMENTS_STORE_VARIABLES[*]}; do
        echo -e "\t${OPTIONAL_ARGUMENTS_NAMES[${i}]}\t\t${OPTIONAL_ARGUMENTS_HELP_MESSAGES[${i}]} (default: ${OPTIONAL_ARGUMENTS_DEFAULT_VALUES[${i}]})"
    done
    echo "Positional arguments:"
    for i in ${!POSITIONAL_ARGUMENTS_STORE_VARIABLES[*]}; do
        echo -e "\t${POSITIONAL_ARGUMENTS_STORE_VARIABLES[${i}]}\t\t${POSITIONAL_ARGUMENTS_HELP_MESSAGES[${i}]}"
    done
}

print_arguments_usage_message() {
    for i in ${!OPTIONAL_ARGUMENTS_STORE_VARIABLES[*]}; do
        echo -en "[${OPTIONAL_ARGUMENTS_NAMES[${i}]} ${OPTIONAL_ARGUMENTS_STORE_VARIABLES[${i}]}]"
        echo -n " "
    done
    for i in ${!POSITIONAL_ARGUMENTS_STORE_VARIABLES[*]}; do
        echo -en "${POSITIONAL_ARGUMENTS_STORE_VARIABLES[${i}]}"
        echo -n " "
    done
    echo
}

arguments() {
    local positional_arguments_count=0
    while (($# != 0)); do
        argument=${1}
        if [[ ${argument} == "--"* ]]; then
            index=$(index_of OPTIONAL_ARGUMENTS_NAMES "${argument}")
            if [[ "${index}" != "" ]]; then
                shift
                argument=${1}
                eval "${OPTIONAL_ARGUMENTS_STORE_VARIABLES[${index}]}=${argument}"
            else
                log -ent "Option ${argument} is not declared!"
                exit 1
            fi
        else
            if ((${positional_arguments_count} < ${#POSITIONAL_ARGUMENTS_STORE_VARIABLES[@]})); then
                eval "${POSITIONAL_ARGUMENTS_STORE_VARIABLES[${positional_arguments_count}]}=${argument}"
                positional_arguments_count=$((${positional_arguments_count} + 1))
            else
                log -ent "Too many positional arguments!"
                exit 1
            fi
        fi
        shift
    done

    for i in ${!OPTIONAL_ARGUMENTS_STORE_VARIABLES[*]}; do
        if [[ "${!OPTIONAL_ARGUMENTS_STORE_VARIABLES[${i}]}" == "" ]]; then
            eval "${OPTIONAL_ARGUMENTS_STORE_VARIABLES[${i}]}=${OPTIONAL_ARGUMENTS_DEFAULT_VALUES[${i}]}"
        fi
    done
}

index_of() {
    local array=${1}[@]
    local value=${2}
    local index=0

    for element in ${!array}; do
        if [[ ${element} == ${value} ]]; then
            echo ${index}
            return 0
        fi
        index=$((index + 1))
    done
    return 1
}
