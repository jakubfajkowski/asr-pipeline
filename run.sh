#!/usr/bin/env bash

source ./path.sh
source $(which log.sh)
source $(which execute.sh)

readonly SCRIPT_NAME="$(realpath ${0})"
readonly SCRIPT_DIR="$(dirname ${SCRIPT_NAME})"
readonly RECIPE_NAME=${1}

main() {
    load_file "${RECIPES_ROOT}/${RECIPE_NAME}"

    build_dir="${BUILDS_ROOT}/${lang}/${version}"
    export LOG="${build_dir}/LOG"
    exp_dir="${build_dir}/exp"
    data_dir="${build_dir}/data"
    test_dir="${data_dir}/test"
    train_dir="${data_dir}/train"
    mfcc_dir="${build_dir}/mfcc"
    lang_dir="${build_dir}/lang"
    local_dir="${build_dir}/local"
    dict_dir="${local_dir}/dict"
    log_dir="${build_dir}/log"
    
    corpus="corpus.txt"
    spk2gender="spk2gender"
    text="text"
    wav_scp="wav.scp"
    words="words"
    lexicon_txt="lexicon.txt"
    utt2spk="utt2spk"
    spk2utt="spk2utt"
    silence_phones="silence_phones.txt"
    nonsilence_phones="nonsilence_phones.txt"
    optional_silence="optional_silence.txt"

    prepare_build_dir
    copy_data
    prepare_data ${train_dir}
    prepare_data ${test_dir}
    prepare_local
    build_model
}

load_file() {
    file=${1}
    log.sh -itn "Loading ${file}"
    source ${file} || exit 1
}

prepare_build_dir() {
#    execute "Cleaning build directory: ${build_dir}" \
#    rm -rf ${build_dir}

    execute "Build directory is: ${build_dir}" \
    mkdir -p ${build_dir}

    mkdir -p ${exp_dir}
    mkdir -p ${data_dir}
    mkdir -p ${test_dir}
    mkdir -p ${train_dir}
    mkdir -p ${mfcc_dir}
    mkdir -p ${lang_dir}
    mkdir -p ${local_dir}
    mkdir -p ${log_dir}
}

copy_data() {
    cp -r ${corpus_train}/* ${train_dir}
    cp -r ${corpus_test}/* ${test_dir}
}

prepare_data() {
    dir=${1}

#    execute "Generating speaker to gender mapping..." \
#    ./local/make_spk2gender.py "${dir}/[MF]???" > "${dir}/${spk2gender}"
#
#    execute "Generating utterance id to wav file mapping..." \
#    ./local/make_wav_scp.py "${dir}/*/*.wav" > "${dir}/${wav_scp}"
#
#    execute "Joining all text files..." \
#    ./local/make_text.sh "${dir}/*/*transcription.tsv" > "${dir}/${text}"
#
#    execute "Tokenizing words used in utterances..." \
#    ./local/make_words.py "${dir}/${text}" > "${dir}/${words}"
#
#    execute "Generating grapheme to phoneme mapping..." \
#    ./local/make_data_lexicon.sh "${dir}/${words}" "${lang}" > "${dir}/${lexicon_txt}"
#
#    execute "Preparing utt2spk..." \
#    ./local/make_utt2spk.sh "${dir}" > "${dir}/${utt2spk}"
#
#    execute "Preparing spk2utt..." \
#	./utils/utt2spk_to_spk2utt.pl "${dir}/${utt2spk}" > "${dir}/${spk2utt}"

    execute "Preparing MFCC features..." \
    steps/features/mfcc.sh --log-dir ${log_dir} ${dir}

    execute "Computing CMVN stats..." \
	steps/statistics/cmvn.sh --log-dir ${log_dir} ${dir}
}

prepare_local() {
    mkdir "${local_dir}/dict"

    execute "Preparing corpus..." \
    ./local/make_corpus.sh "${train_dir}/${text}" "${test_dir}/${text}" > "${local_dir}/corpus.txt"

    execute "Preparing silence phones..." \
    ./local/make_silence_phones.sh > "${local_dir}/dict/silence_phones.txt"

    execute "Preparing optional silence..." \
    ./local/make_optional_silence.sh > "${local_dir}/dict/optional_silence.txt"

    execute "Preparing nonsilence phones..." \
    ./local/make_nonsilence_phones.sh ${data_dir}/*/lexicon.txt > "${local_dir}/dict/nonsilence_phones.txt"

    execute "Preparing lexicon..." \
    ./local/make_local_lexicon.sh ${data_dir}/*/lexicon.txt > "${local_dir}/dict/lexicon.txt"
}

build_model() {
    execute "Preparing ${ngram_order}-gram language model..." \
    ngram-count -order ${ngram_order} -wbdiscount -text "${local_dir}/corpus.txt" -lm "${local_dir}/lm.arpa"

	utils/prepare_lang.sh "${local_dir}/dict" "<UNK>" "${local_dir}/lang" "${lang_dir}"
	arpa2fst --disambig-symbol="#0" "${local_dir}/lm.arpa" "${lang_dir}/G.fst"

	steps/train_mono.sh --nj 4 --totgauss 400 ${train_dir} ${lang_dir} ${exp_dir}/mono
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono
    score ${exp_dir}/mono

    steps/align_si.sh --nj 1 ${train_dir} ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono_aligned
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono_aligned ${exp_dir}/mono_aligned/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/mono_aligned ${exp_dir}/mono_aligned
    score ${exp_dir}/mono_aligned

    steps/train_deltas.sh 2000 11000 ${train_dir} ${lang_dir} ${exp_dir}/mono_aligned ${exp_dir}/tri
    utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri ${exp_dir}/tri/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri ${exp_dir}/tri
    score ${exp_dir}/tri

}

score() {
    model_dir=${1}

    steps/decode.sh --nj 1 --skip-scoring true \
	${model_dir}/graph ${test_dir} ${model_dir}/offline
	steps/score_kaldi.sh \
	${test_dir} ${model_dir}/graph ${model_dir}/offline

	steps/online/decode.sh --nj 1 --skip-scoring true \
	${model_dir}/graph ${test_dir} ${model_dir}/online
	steps/score_kaldi.sh \
	${test_dir} ${model_dir}/graph ${model_dir}/online
}

main