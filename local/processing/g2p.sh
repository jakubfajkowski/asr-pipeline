#!/bin/bash

to_phonemes() {
    language=${1}
    espeak -v ${language} -q -x --ipa=3 |
    sed -e 's/ //' -e 's:_: :g' -e 's/ː//g' -e 's/ˈ//g' -e 's/ˌ//g'
}

main() {
    language=${1}; shift
    files=$@

    if [ "${language}" == "" ]; then
        echo "You must specify language!" >&2
        exit 1
    fi

    if [ "${files}" != "" ]; then
        for file in ${files}; do
            paste ${file} <(to_phonemes ${language} < ${file})
        done
    else
        file=$(mktemp)
        cat > ${file}
        paste ${file} <(to_phonemes ${language} < ${file})
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
