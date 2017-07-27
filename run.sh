#!/bin/bash

readonly SCRIPT="$(realpath ${0})"
readonly ROOT_DIR="$(dirname ${SCRIPT})"
readonly TOOLS_DIR="${ROOT_DIR}/tools"
readonly SETTINGS="${ROOT_DIR}/settings.cfg"
readonly CONFIG_NAME=${1}

main() {
    load_dependencies
    corpus_dir="${CORPORA_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
    build_dir="${BUILDS_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
    prepare_corpus "${corpus_dir}" "${build_dir}"
}

load_dependencies() {
    load_log_tool
    log -itn "Loading dependencies..."
    load_file "${SETTINGS}"
    load_file "${CONFIGS_DIR}/${CONFIG_NAME}"
}

load_log_tool() {
    source $(which log.sh)
}

load_file() {
    file=${1}
    log -itn "Loading ${file}"
    source ${file}
}

prepare_corpus() {
    corpus_dir=${1}
    build_dir=${2}

    change_directory_to_build_dir
    clean_current_directory
    split_audio_data



#    log.sh -it "Generating speaker to gender mapping..."
#    prepare_spk2gender.py ${corpus_dir} > spk2gender
#    log.sh -n "\t\t\tDONE"
#
#    log.sh -it "Generating utterance id to wav file mapping..."
#    prepare_wav_scp.py ${corpus_dir} > wav.scp
#    log.sh -n "\tDONE"
#
#    log.sh -it "Tokenizing words used in utterances..."
#    prepare_words.py ${corpus_dir} > words
#    log.sh -n "\t\t\tDONE"
#
#    log.sh -it "Generating grapheme to phoneme mapping..."
#    ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w words -l ${CORPUS_LANG:0:2} > words_g2p
#    log.sh -n "\t\tDONE"
}

change_directory_to_build_dir() {
    log -itn "Changing directory to ${build_dir}"
    mkdir -p ${build_dir}
    cd ${build_dir}
}

clean_current_directory() {
    log -itn "Cleaning current directory."
    rm -rf *
}

split_audio_data() {
    log -it "Splitting audio data to test and train sets..."
    run split_data.py "${corpus_dir}/*/*.wav" "${build_dir}" "${SPLIT_RATIO}"
}

run() {
    if $@ 2> ${ERROR_LOG}; then
        log -n "\t\t\tDONE"
    else
        log -n "\t\t\tFAILURE"
        exit 1
    fi
}

main

