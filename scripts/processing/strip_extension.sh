#!/usr/bin/env bash

strip_specific_extension() {
    local extension=${1}
    while read filename; do
        basename ${filename} ${extension}
    done
}

strip_any_extension() {
    perl -pe "s/\.[^.]+$//"
}

main() {
    extension=${1}
    if [ "${extension}" != "" ]; then
        strip_specific_extension ${extension}
    else
        strip_any_extension
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi