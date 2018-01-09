#!/bin/bash

set -o pipefail
source utils.sh
readonly LOG=build.log

execute() {
    log -int "${message}"
    if ${command} 2> >(tee -a ${LOG} >&2); then
        log -dnt "${message}"
    else
        log -ent "${message}"
        exit 1
    fi
}

shift; message="${1}"; shift
shift; command="${1}"; shift
shift; input_file="${1}"; shift
shift; output_file="${1}"; shift


if [ -f "${input_file}+" ]; then
    cat ${input_file}+ >> ${input_file}
    rm ${input_file}+
fi

if [[ "${input_file}" == *'~' ]]; then
    touch "${input_file}"
fi

if [ "${input_file}" == "" ] && [ "${output_file}" == "" ]; then
    log -xnt "${command}"
    execute
elif [ "${input_file}" == "" ]; then
    log -xnt "${command} | sponge ${output_file}"
    execute | sponge ${output_file}
elif [ "${output_file}" == "" ]; then
    log -xnt "< ${input_file} ${command}"
    < ${input_file} execute
else
    log -xnt "< ${input_file} ${command} | sponge ${output_file}"
    < ${input_file} execute | sponge ${output_file}
fi


if [ -f "${output_file}+" ]; then
    cat "${output_file}+" >> ${output_file}
    rm "${output_file}+"
fi
