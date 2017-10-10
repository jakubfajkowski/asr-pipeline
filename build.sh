#!/usr/bin/env bash

source ./scripts/utils/log.sh
source ./scripts/utils/run.sh

readonly SCRIPT_NAME="$(realpath ${0})"
readonly SCRIPT_DIR="$(dirname ${SCRIPT_NAME})"
readonly SETTINGS="${SCRIPT_DIR}/settings.cfg"
readonly CONFIG_NAME=${1}

main() {
    load_dependencies

    corpus_dir="${CORPORA_DIR}/${corpus_lang}/${corpus_name}"
    build_dir="${BUILDS_DIR}/${corpus_name}/${corpus_name}"

    exp_dir="${build_dir}/exp"
    data_dir="${build_dir}/data"
    test_dir="${data_dir}/test"
    train_dir="${data_dir}/train"
    mfcc_dir="${build_dir}/mfcc"
    lang_dir="${build_dir}/lang"
    local_dir="${build_dir}/local"

#    ln -s ${KALDI_DIR}/egs/wsj/s5/utils utils
#    ln -s ${KALDI_DIR}/egs/wsj/s5/steps steps
#    prepare_build_dir
#    split_data
#    prepare_data ${train_dir}
#    prepare_data ${test_dir}
#    prepare_local
    build_model
}

load_dependencies() {
    load_file "${SETTINGS}"
    load_file "${CONFIGS_DIR}/${CONFIG_NAME}"
    load_file "${KALDI_DIR}/tools/env.sh"
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

    mkdir -p ${exp_dir}
    mkdir -p ${data_dir}
    mkdir -p ${test_dir}
    mkdir -p ${train_dir}
    mkdir -p ${mfcc_dir}
    mkdir -p ${lang_dir}
    mkdir -p ${local_dir}
}

split_data() {
    run "Splitting audio data to test and train sets..." \
    make_split.py "${corpus_dir}/*" "${data_dir}" "${split_ratio}"
}

prepare_data() {
    lang=$(echo ${corpus_lang} | cut -d '-' -f1)
    spk2gender="spk2gender"
    text="text"
    wav_scp="wav.scp"
    words="words"
    lexicon="lexicon.txt"
    utt2spk="utt2spk"

    dir=${1}

    run "Generating speaker to gender mapping..." \
    make_spk2gender.py "${dir}/[MF]???" > "${dir}/${spk2gender}"

    run "Generating utterance id to wav file mapping..." \
    make_wav_scp.py "${dir}/*/*.wav" > "${dir}/${wav_scp}"

    run "Joining all text files..." \
    make_text.sh "${dir}/*/*transcription.tsv" > "${dir}/${text}"

    run "Tokenizing words used in utterances..." \
    make_words.py "${dir}/${text}" > "${dir}/${words}"

    run "Generating grapheme to phoneme mapping..." \
    ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w "${dir}/${words}" -l "${lang}" > "${dir}/${lexicon}"

    run "Preparing utt2spk..." \
    make_utt2spk.sh "${dir}" > "${dir}/${utt2spk}"
}

prepare_local() {
    mkdir "${local_dir}/dict"

    run "Preparing corpus..." \
    make_corpus.sh "${corpus_dir}/*/*transcription.tsv" > "${local_dir}/corpus.txt"

    run "Preparing silence phones..." \
    make_silence_phones.sh > "${local_dir}/dict/silence_phones.txt"

    run "Preparing optional silence..." \
    make_optional_silence.sh > "${local_dir}/dict/optional_silence.txt"

    run "Preparing nonsilence phones..." \
    make_nonsilence_phones.sh > "${local_dir}/dict/nonsilence_phones.txt"

    run "Preparing lexicon..." \
    cat ${test_dir}/lexicon.txt ${train_dir}/lexicon.txt | sort -u > "${local_dir}/dict/lexicon.txt"
    echo -e "<UNK>\tspn" >> "${local_dir}/dict/lexicon.txt"
}

build_model() {
    source ./path.sh
    train_cmd="utils/run.pl"
    decode_cmd="utils/run.pl"


#    # Making spk2utt files
#    utils/utt2spk_to_spk2utt.pl ${train_dir}/utt2spk > ${train_dir}/spk2utt
#    utils/utt2spk_to_spk2utt.pl ${test_dir}/utt2spk > ${test_dir}/spk2utt
#
#
#    utils/prepare_lang.sh ${local_dir}/dict "<UNK>" ${local_dir}/lang ${lang_dir}
#
#    echo
#    echo "===== LANGUAGE MODEL CREATION ====="
#    echo "===== MAKING lm.arpa ====="
#    echo
#
#    mkdir ${local_dir}/tmp
#    ngram-count -order 1 -write-vocab ${local_dir}/tmp/vocab-full.txt -wbdiscount -text ${local_dir}/corpus.txt -lm ${local_dir}/tmp/lm.arpa
#    #ngram-count -order 1 -text ${local_dir}/corpus.txt -lm ${local_dir}/tmp/lm.arpa
#
#    echo
#    echo "===== MAKING G.fst ====="
#    echo
#
#    arpa2fst --disambig-symbol="#0" --read-symbol-table=${lang_dir}/words.txt ${local_dir}/tmp/lm.arpa ${lang_dir}/G.fst
#
#    utils/validate_lang.pl ${lang_dir}
#
#    # Feature extraction
#    steps/make_mfcc.sh --nj 1 ${train_dir} ${build_dir}/exp/make_mfcc/train ${mfcc_dir}
#    steps/compute_cmvn_stats.sh ${train_dir} ${build_dir}/exp/make_mfcc/train ${mfcc_dir}
#    utils/fix_data_dir.sh ${train_dir}
#
#    steps/make_mfcc.sh --nj 1 ${test_dir} ${build_dir}/exp/make_mfcc/test ${mfcc_dir}
#    steps/compute_cmvn_stats.sh ${test_dir} ${build_dir}/exp/make_mfcc/test ${mfcc_dir}
#    utils/fix_data_dir.sh ${test_dir}
#
#
#    # Mono training
#    steps/train_mono.sh --nj 4 --cmd "${train_cmd}" \
#    --totgauss 400 \
#    ${train_dir} ${lang_dir} ${build_dir}/exp/mono
#
#    # Graph compilation
#    utils/mkgraph.sh ${lang_dir} ${exp_dir}/mono ${exp_dir}/mono/graph
#
#    # Decoding
#    steps/decode.sh --nj 1 --cmd "$decode_cmd" \
#    ${exp_dir}/mono/graph ${test_dir} ${build_dir}/exp/mono/decode

#
#    # Online decoding
#    ./steps/online/prepare_online_decoding.sh --cmd "$decode_cmd" \
#    ${train_dir} ${lang_dir} ${build_dir}/exp/mono ${build_dir}/exp/mono_online

    ./steps/online/decode.sh --nj 1 --cmd "$decode_cmd" \
    ${exp_dir}/mono/graph ${test_dir} ${build_dir}/exp/mono_online/decode

#    source ./path.sh
#    train_cmd="utils/run.pl"
#    decode_cmd="utils/run.pl"
#
#    nj=1       # number of parallel jobs - 1 is perfect for such a small data set
#    lm_order=1 # language model order (n-gram quantity) - 1 is enough for digits grammar
#
#    echo
#    echo "===== PREPARING ACOUSTIC DATA ====="
#    echo
#
#    # Needs to be prepared by hand (or using self written scripts):
#    #
#    # spk2gender  [<speaker-id> <gender>]
#    # wav.scp     [<uterranceID> <full_path_to_audio_file>]
#    # text        [<uterranceID> <text_transcription>]
#    # utt2spk     [<uterranceID> <speakerID>]
#    # corpus.txt  [<text_transcription>]
#
#    # Making spk2utt files
#    utils/utt2spk_to_spk2utt.pl ${build_dir}/train/utt2spk > ${build_dir}/train/spk2utt
#    utils/utt2spk_to_spk2utt.pl ${build_dir}/test/utt2spk > ${build_dir}/test/spk2utt
#
#    echo
#    echo "===== FEATURES EXTRACTION ====="
#    echo
#
#    # Making feats.scp files
#    mfccdir=${build_dir}/mfcc
#    # Uncomment and modify arguments in scripts below if you have any problems with data sorting
#    # utils/validate_data_dir.sh data/train     # script for checking prepared data - here: for data/train directory
#    # utils/fix_data_dir.sh data/train          # tool for data proper sorting if needed - here: for data/train directory
#    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" ${build_dir}/train ${build_dir}/exp/make_mfcc/train $mfccdir
#    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" ${build_dir}/test ${build_dir}/exp/make_mfcc/test $mfccdir
#
#    # Making cmvn.scp files
#    steps/compute_cmvn_stats.sh ${build_dir}/train ${build_dir}/exp/make_mfcc/train $mfccdir
#    steps/compute_cmvn_stats.sh ${build_dir}/test ${build_dir}/exp/make_mfcc/test $mfccdir
#
#    echo
#    echo "===== PREPARING LANGUAGE DATA ====="
#    echo
#
#    # Needs to be prepared by hand (or using self written scripts):
#    #
#    # lexicon.txt           [<word> <phone 1> <phone 2> ...]
#    # nonsilence_phones.txt    [<phone>]
#    # silence_phones.txt    [<phone>]
#    # optional_silence.txt  [<phone>]
#
#    # Preparing language data
#    utils/prepare_lang.sh ${build_dir}/local/dict "<UNK>" ${build_dir}/local/lang ${build_dir}/lang
#
#    echo
#    echo "===== LANGUAGE MODEL CREATION ====="
#    echo "===== MAKING lm.arpa ====="
#    echo
#
#    loc=`which ngram-count`;
#    if [ -z $loc ]; then
#       if uname -a | grep 64 >/dev/null; then
#               sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
#       else
#                       sdir=$KALDI_ROOT/tools/srilm/bin/i686
#       fi
#       if [ -f $sdir/ngram-count ]; then
#                       echo "Using SRILM language modelling tool from $sdir"
#                       export PATH=$PATH:$sdir
#       else
#                       echo "SRILM toolkit is probably not installed.
#                               Instructions: tools/install_srilm.sh"
#                       exit 1
#       fi
#    fi
#
#    local=${build_dir}/local
#    mkdir $local/tmp
#    ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa
#
#    echo
#    echo "===== MAKING G.fst ====="
#    echo
#
#    lang=${build_dir}/lang
#    arpa2fst --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst
#
#    echo
#    echo "===== MONO TRAINING ====="
#    echo
#
#    steps/train_mono.sh --nj $nj --cmd "$train_cmd" ${build_dir}/train ${build_dir}/lang ${build_dir}/exp/mono  || exit 1
#
#
#    echo
#    echo "===== MONO DECODING ====="
#    echo
#
#    utils/mkgraph.sh --mono ${build_dir}/lang ${build_dir}/exp/mono ${build_dir}/exp/mono/graph || exit 1
#    steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" ${build_dir}/exp/mono/graph ${build_dir}/test ${build_dir}/exp/mono/decode
#
#    echo
#    echo "===== MONO ALIGNMENT ====="
#    echo
#
#    steps/align_si.sh --nj $nj --cmd "$train_cmd" ${build_dir}/train ${build_dir}/lang ${build_dir}/exp/mono ${build_dir}/exp/mono_ali || exit 1
#
#    echo
#    echo "===== TRI1 (first triphone pass) TRAINING ====="
#    echo
#
#    steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 ${build_dir}/train ${build_dir}/lang ${build_dir}/exp/mono_ali ${build_dir}/exp/tri1 || exit 1
#
#    echo
#    echo "===== TRI1 (first triphone pass) DECODING ====="
#    echo
#
#    utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
#    steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" ${build_dir}/exp/tri1/graph ${build_dir}/test ${build_dir}/exp/tri1/decode
#
#    echo
#    echo "===== run.sh script is finished ====="
#    echo
}

main