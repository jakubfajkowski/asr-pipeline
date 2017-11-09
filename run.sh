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
    
    corpus="corpus.txt"
    spk2gender="spk2gender"
    text="text"
    wav_scp="wav.scp"
    words="words.txt"
    lexicon="lexicon.txt"
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
    execute "Cleaning build directory: ${build_dir}" \
    rm -rf ${build_dir}

    execute "Build directory is: ${build_dir}" \
    mkdir -p ${build_dir}

    mkdir -p ${exp_dir}
    mkdir -p ${data_dir}
    mkdir -p ${test_dir}
    mkdir -p ${train_dir}
    mkdir -p ${mfcc_dir}
    mkdir -p ${lang_dir}
    mkdir -p ${local_dir}
}

copy_data() {
    cp -r ${corpus_train}/* ${train_dir}
    cp -r ${corpus_test}/* ${test_dir}
}

prepare_data() {
    dir=${1}

    execute "Generating utterance id to wav file mapping..." \
    ./local/make_wav_scp.sh "${dir}/*/*.wav" > "${dir}/${wav_scp}"

    execute "Joining all text files..." \
    ./local/make_text.sh "${dir}/*/*transcription.tsv" > "${dir}/${text}"

    execute "Preparing corpus..." \
    ./local/make_data_corpus.sh "${dir}/${text}" > "${dir}/${corpus}"

    execute "Tokenizing words used in utterances..." \
    ./local/make_words.sh "${lang}" "${dir}/${corpus}" > "${dir}/${words}"

    execute "Generating grapheme to phoneme mapping..." \
    ./local/make_data_lexicon.sh "${dir}/${words}" "${lang}" > "${dir}/${lexicon}"

    execute "Preparing utt2spk..." \
    ./local/make_utt2spk.sh "${dir}" > "${dir}/${utt2spk}"

    execute "Preparing spk2utt..." \
	./utils/utt2spk_to_spk2utt.pl "${dir}/${utt2spk}" > "${dir}/${spk2utt}"

    steps/make_mfcc.sh --nj 1 ${dir} ${dir}/log ${mfcc_dir}
	steps/compute_cmvn_stats.sh ${dir} ${dir}/log ${mfcc_dir}
	utils/fix_data_dir.sh ${dir}
}

prepare_local() {
    mkdir "${local_dir}/dict"

    execute "Preparing silence phones..." \
    ./local/make_silence_phones.sh > "${local_dir}/dict/silence_phones.txt"

    execute "Preparing optional silence..." \
    ./local/make_optional_silence.sh > "${local_dir}/dict/optional_silence.txt"

    execute "Preparing nonsilence phones..." \
    ./local/make_nonsilence_phones.sh ${data_dir}/*/lexicon.txt > "${local_dir}/dict/nonsilence_phones.txt"

    execute "Preparing corpus..." \
    ./local/make_local_corpus.sh ${data_dir}/*/${corpus} > "${local_dir}/${corpus}"

    execute "Preparing lexicon..." \
    ./local/make_local_lexicon.sh ${data_dir}/*/lexicon.txt > "${local_dir}/dict/lexicon.txt"
}

build_model() {
    ngram-count -order ${ngram_order} -wbdiscount -text "${local_dir}/corpus.txt" -lm "${local_dir}/lm.arpa"
	utils/prepare_lang.sh "${local_dir}/dict" "<UNK>" "${local_dir}/lang" "${lang_dir}"
	arpa2fst --disambig-symbol="#0" --read-symbol-table="${lang_dir}/words.txt" "${local_dir}/lm.arpa" "${lang_dir}/G.fst"

    echo "Train monophone models on full data -> may be wastefull (can be done on subset)"
    steps/train_mono.sh --nj 4 ${train_dir} ${lang_dir} ${exp_dir}/mono || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono
    score ${exp_dir}/mono

    echo "Get alignments from monophone system."
    steps/align_si.sh --nj 4 ${train_dir} ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono_ali || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono_ali ${exp_dir}/mono_ali/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/mono_ali ${exp_dir}/mono_ali
    score ${exp_dir}/mono_ali

    echo "Train tri1 [first triphone pass]"
    steps/train_deltas.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/mono_ali ${exp_dir}/tri1 || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri1 ${exp_dir}/tri1/graph
    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri1 ${exp_dir}/tri1
    score ${exp_dir}/tri1

#    echo "Align tri1"
#    steps/align_si.sh --nj 4 --use-graphs true ${train_dir} ${lang_dir} ${exp_dir}/tri1 ${exp_dir}/tri1_ali || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri1_ali/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri1_ali
#    score ${exp_dir}/tri1_ali
#
#    echo "Train tri2a [delta+delta-deltas]"
#    steps/train_deltas.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri2a || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2a ${exp_dir}/tri2a/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2a ${exp_dir}/tri2a
#    score ${exp_dir}/tri2a
#
#    echo "Train tri2b [LDA+MLLT]"
#    steps/train_lda_mllt.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri2b || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b
#    score ${exp_dir}/tri2b
#
#    echo "Align all data with LDA+MLLT system (tri2b)"
#    steps/align_si.sh  --nj 4 --use-graphs true ${train_dir} ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b_ali || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri2b_ali/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri2b_ali
#    score ${exp_dir}/tri2b_ali
#
#    echo "Train MMI on top of LDA+MLLT."
#    steps/make_denlats.sh  --nj 4 ${train_dir} ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b_denlats || exit 1
#    steps/train_mmi.sh  ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri2b_denlats ${exp_dir}/tri2b_mmi || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b_mmi ${exp_dir}/tri2b_mmi/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b_mmi ${exp_dir}/tri2b_mmi
#    score ${exp_dir}/tri2b_mmi
#
#    echo "Train MMI on top of LDA+MLLT with boosting. train_mmi_boost is a e.g. 0.05"
#    steps/train_mmi.sh  --boost ${train_mmi_boost} ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri2b_denlats ${exp_dir}/tri2b_mmi_b${train_mmi_boost} || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b_mmi_b${train_mmi_boost} ${exp_dir}/tri2b_mmi_b${train_mmi_boost}/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b_mmi_b${train_mmi_boost} ${exp_dir}/tri2b_mmi_b${train_mmi_boost}
#    score ${exp_dir}/tri2b_mmi_b${train_mmi_boost}
#
#    echo "Train MPE."
#    steps/train_mpe.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri2b_denlats ${exp_dir}/tri2b_mpe || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b_mpe ${exp_dir}/tri2b_mpe/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri2b_mpe ${exp_dir}/tri2b_mpe
#    score ${exp_dir}/tri2b_mpe
#
#    steps/train_sat.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri3b || exit 1
#	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri3b ${exp_dir}/tri3b/graph
#    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${exp_dir}/tri3b ${exp_dir}/tri3b
#    score ${exp_dir}/tri3b
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