#!/usr/bin/env bash

source $(which log.sh)
source $(which run.sh)

readonly SCRIPT="$(realpath ${0})"
readonly ROOT_DIR="$(dirname ${SCRIPT})"
readonly TOOLS_DIR="${ROOT_DIR}/tools"
readonly SETTINGS="${ROOT_DIR}/settings.cfg"
readonly CONFIG_NAME=${1}

main() {
    load_dependencies

    corpus_dir="${CORPORA_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
    build_dir="${BUILDS_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"

    prepare_build_dir
    split_data
    prepare_data "${build_dir}/test"
    prepare_data "${build_dir}/train"
}

load_dependencies() {
    load_file "${SETTINGS}"
    load_file "${CONFIGS_DIR}/${CONFIG_NAME}"
}

load_file() {
    file=${1}
    log.sh -itn "Loading ${file}"
    source ${file}
}

prepare_build_dir() {
    run "Cleaning build directory: ${build_dir}" \
    rm -rf ${build_dir}

    run "Build directory is: ${build_dir}" \
    mkdir -p ${build_dir}
}

split_data() {
    run "Splitting audio data to test and train sets..." \
    make_split.py "${corpus_dir}/*" "${build_dir}" "${SPLIT_RATIO}"
}

prepare_data() {
    lang=$(echo ${CORPUS_LANG} | cut -d '-' -f1)
    spk2gender="spk2gender.txt"
    text="text.txt"
    wav_scp="wav.scp"
    words="words.txt"
    g2p="g2p.txt"

    data_dir=${1}

    run "Generating speaker to gender mapping..." \
    make_spk2gender.py "${data_dir}/[MF]???" > "${data_dir}/${spk2gender}"

    run "Generating utterance id to wav file mapping..." \
    make_wav_scp.py "${data_dir}/*/*.wav" > "${data_dir}/${wav_scp}"

    run "Joining all text files..." \
    make_text.sh "${data_dir}/*/transcription.tsv" > "${data_dir}/${text}"

    run "Tokenizing words used in utterances..." \
    make_words.py "${data_dir}/${text}" > "${data_dir}/${words}"

    run "Generating grapheme to phoneme mapping..." \
    ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w "${data_dir}/${words}" -l "${lang}" > "${data_dir}/${g2p}"
}

main