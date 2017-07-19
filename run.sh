#!/bin/bash

readonly SCRIPT="$(realpath ${0})"
readonly ROOT_DIR="$(dirname ${SCRIPT})"
readonly TOOLS_DIR="${ROOT_DIR}/tools"
readonly SETTINGS="${ROOT_DIR}/settings.cfg"
readonly CONFIG_NAME=${1}

main() {
    load_dependencies
    prepare_corpus "${CORPORA_DIR}/${CORPUS_LANG}/${CORPUS_NAME}" "${BUILDS_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
}

load_dependencies() {
    logger.sh -itn "Loading dependencies..."
    load_file "${SETTINGS}"
    load_file "${CONFIGS_DIR}/${CONFIG_NAME}"
}

load_file() {
    file=${1}
    logger.sh -itn "Loading ${file}"
    source ${file}
}

prepare_corpus() {
    corpus_dir=${1}
    build_dir=${2}

    logger.sh -itn "Changing directory to ${build_dir}"
    mkdir -p ${build_dir}
    cd ${build_dir}

    logger.sh -it "Generating speaker to gender mapping..."
    prepare_spk2gender.py ${corpus_dir} > spk2gender
    logger.sh -n "\t\t\tDONE"

    logger.sh -it "Generating utterance id to wav file mapping..."
    prepare_wav_scp.py ${corpus_dir} > wav.scp
    logger.sh -n "\tDONE"

    logger.sh -it "Tokenizing words used in utterances..."
    prepare_words.py ${corpus_dir} > words
    logger.sh -n "\t\t\tDONE"

    logger.sh -it "Generating grapheme to phoneme mapping..."
    ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w words -l ${CORPUS_LANG:0:2} > words_g2p
    logger.sh -n "\t\tDONE"
}

main

