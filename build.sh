#!/usr/bin/env bash

source ./path.sh
source ./utils.sh

readonly SCRIPT_NAME="$(realpath ${0})"
readonly SCRIPT_DIR="$(dirname ${SCRIPT_NAME})"
readonly RECIPE_NAME=${1}

load_recipe() {
    file=${1}
    log -itn "Loading ${file}"
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
    mkdir -p ${lang_dir}
    mkdir -p ${local_dir}
}

copy_data() {
    cp -r ${corpus_train}/* ${train_dir}
    cp -r ${corpus_test}/* ${test_dir}
    if [ -d "${corpus_local}" ]; then
        cp -r ${corpus_local}/* ${local_dir}
    fi
}

prepare_audio_data() {
    dir=${1}

    execute "Generating utterance id to wav file mapping..." \
    ./local/make_wav_scp.sh "${dir}/*/*.wav" > "${dir}/${wav_scp}"

    execute "Joining all text files..." \
    ./local/make_text.sh "${lang}" "${dir}/*/*transcription.tsv" > "${dir}/${text}"

    execute "Preparing corpus..." \
    ./local/make_data_corpus.sh "${lang}" "${dir}/${text}" > "${dir}/${corpus}"

    execute "Tokenizing words used in utterances..." \
    ./local/make_words.sh "${lang}" "${dir}/${corpus}" > "${dir}/${words}"

    execute "Generating grapheme to phoneme mapping..." \
    ./local/make_data_lexicon.sh "${dir}/${words}" "${lang}" | ./local/processing/fix.py "${local_dir}/dict/${lexicon_rules}" > "${dir}/${lexicon}"

    execute "Preparing utt2spk..." \
    ./local/make_utt2spk.sh "${dir}" > "${dir}/${utt2spk}"

    execute "Preparing spk2utt..." \
	./utils/utt2spk_to_spk2utt.pl "${dir}/${utt2spk}" > "${dir}/${spk2utt}"


    case ${feature_type} in
    fbank)
        steps/make_fbank.sh --nj 4 ${dir} ${dir}/log ${dir}
        ;;
    mfcc)
        steps/make_mfcc.sh --nj 4 ${dir} ${dir}/log ${dir}
        ;;
    plp)
        steps/make_plp.sh --nj 4 ${dir} ${dir}/log ${dir}
        ;;
    esac

	steps/compute_cmvn_stats.sh ${dir} ${dir}/log ${dir}
	utils/fix_data_dir.sh ${dir}
}

prepare_language_data() {
    mkdir -p "${local_dir}/dict"

    execute "Preparing corpus..." \
    ./local/make_local_corpus.sh ${lang} ${local_dir}/${corpus} | sponge "${local_dir}/${corpus}"

    execute "Preparing lexicon..." \
    ./local/make_local_lexicon.sh ${data_dir}/*/lexicon.txt ${local_dir}/dict/lexicon.txt | ./local/processing/fix.py "${local_dir}/dict/${lexicon_rules}" | sponge "${local_dir}/dict/lexicon.txt"

    execute "Preparing silence phones..." \
    ./local/make_silence_phones.sh > "${local_dir}/dict/silence_phones.txt"

    execute "Preparing optional silence..." \
    ./local/make_optional_silence.sh > "${local_dir}/dict/optional_silence.txt"

    execute "Preparing nonsilence phones..." \
    ./local/make_nonsilence_phones.sh ${local_dir}/dict/silence_phones.txt ${local_dir}/dict/lexicon.txt > "${local_dir}/dict/nonsilence_phones.txt"
}

train_gmm() {
    ngram-count -order ${ngram_order} -wbdiscount -text "${local_dir}/corpus.txt" -lm "${local_dir}/lm.arpa"
	utils/prepare_lang.sh "${local_dir}/dict" "<UNK>" "${local_dir}/lang" "${lang_dir}"
	arpa2fst --disambig-symbol="#0" --read-symbol-table="${lang_dir}/words.txt" "${local_dir}/lm.arpa" "${lang_dir}/G.fst"

    log -int "Training monophone model."
    steps/train_mono.sh --nj 4 ${train_dir} ${lang_dir} ${exp_dir}/mono || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono/graph || exit 1
    steps/align_si.sh --nj 4 ${train_dir} ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono_ali || exit 1
    score ${exp_dir}/mono
    log -dnt "Training monophone model."

    log -int "Training triphone model (deltas)."
    steps/train_deltas.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/mono_ali ${exp_dir}/tri1 || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri1 ${exp_dir}/tri1/graph || exit 1
    steps/align_si.sh --nj 4 --use-graphs true ${train_dir} ${lang_dir} ${exp_dir}/tri1 ${exp_dir}/tri1_ali || exit 1
    score ${exp_dir}/tri1
    log -int "Training triphone model (deltas)."

    log -int "Training triphone model (deltas and delta-deltas)."
    steps/train_deltas.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri2a || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2a ${exp_dir}/tri2a/graph || exit 1
	score ${exp_dir}/tri2a
    log -dnt "Training triphone model (deltas and delta-deltas)."

    log -int "Training triphone model (LDA and MLLT)."
    steps/train_lda_mllt.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri1_ali ${exp_dir}/tri2b || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b/graph || exit 1
    steps/align_si.sh --nj 4 --use-graphs true ${train_dir} ${lang_dir} ${exp_dir}/tri2b ${exp_dir}/tri2b_ali || exit 1
    score ${exp_dir}/tri2b
    log -dnt "Training triphone model (LDA and MLLT)."

    log -int "Training triphone model (SAT)."
    steps/train_sat.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${lang_dir} ${exp_dir}/tri2b_ali ${exp_dir}/tri3b || exit 1
	utils/mkgraph.sh ${lang_dir} ${exp_dir}/tri3b ${exp_dir}/tri3b/graph || exit 1
	score ${exp_dir}/tri3b
    log -dnt "Training triphone model (SAT)."
}

#score_gmm() {
#    for model_dir in ${exp_dir}/*; do
#        score ${model_dir}
#    done
#}

score() {
    model_dir=${1}

    steps/decode.sh --nj 4 --skip-scoring true \
	${model_dir}/graph ${test_dir} ${model_dir}/offline
	steps/score_kaldi.sh \
	${test_dir} ${model_dir}/graph ${model_dir}/offline

    steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${model_dir} ${model_dir}
	steps/online/decode.sh --nj 4 --skip-scoring true \
	${model_dir}/graph ${test_dir} ${model_dir}/online
	steps/score_kaldi.sh \
	${test_dir} ${model_dir}/graph ${model_dir}/online
}

main() {
    if [ -s ${RECIPE_NAME} ]; then
        load_recipe ${RECIPE_NAME}
    else
        load_recipe ${RECIPES_ROOT}/${RECIPE_NAME}
    fi

    build_dir="${BUILDS_ROOT}/${lang}/${version}"
    export LOG="${build_dir}/LOG"
    exp_dir="${build_dir}/exp"
    data_dir="${build_dir}/data"
    test_dir="${data_dir}/test"
    train_dir="${data_dir}/train"
    lang_dir="${build_dir}/lang"
    local_dir="${build_dir}/local"
    dict_dir="${local_dir}/dict"

    corpus="corpus.txt"
    spk2gender="spk2gender"
    text="text"
    wav_scp="wav.scp"
    words="words.txt"
    lexicon="lexicon.txt"
    lexicon_rules="lexicon.rules"
    utt2spk="utt2spk"
    spk2utt="spk2utt"
    silence_phones="silence_phones.txt"
    nonsilence_phones="nonsilence_phones.txt"
    optional_silence="optional_silence.txt"

    prepare_build_dir
    copy_data
    prepare_audio_data ${train_dir}
    prepare_audio_data ${test_dir}
    prepare_language_data

    train_gmm
#    score_gmm
}

main
