#!/usr/bin/env bash

source $(which log.sh)
source $(which run.sh)

readonly SCRIPT_NAME="$(realpath ${0})"
readonly SCRIPT_DIR="$(dirname ${SCRIPT_NAME})"
readonly SETTINGS="${SCRIPT_DIR}/settings.cfg"
readonly CONFIG_NAME=${1}

main() {
    load_dependencies

    corpus_dir="${CORPORA_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
    build_dir="${BUILDS_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"

    prepare_build_dir
    split_data
    prepare_data "${build_dir}/test"
    prepare_data "${build_dir}/train"
    prepare_local
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
    make_text.sh "${data_dir}/*/*transcription.tsv" > "${data_dir}/${text}"

    run "Tokenizing words used in utterances..." \
    make_words.py "${data_dir}/${text}" > "${data_dir}/${words}"

    run "Generating grapheme to phoneme mapping..." \
    ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w "${data_dir}/${words}" -l "${lang}" > "${data_dir}/${g2p}"
}

prepare_local() {
    local_dir="${build_dir}/local"
    mkdir "${local_dir}"

    run "Preparing corpus..." \
    make_corpus.sh "${corpus_dir}/*/*transcription.tsv" > "${local_dir}/corpus.txt"
}

build_model() {
    nj=1       # number of parallel jobs - 1 is perfect for such a small data set
    lm_order=1 # language model order (n-gram quantity) - 1 is enough for digits grammar

    echo
    echo "===== PREPARING ACOUSTIC DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # spk2gender  [<speaker-id> <gender>]
    # wav.scp     [<uterranceID> <full_path_to_audio_file>]
    # text        [<uterranceID> <text_transcription>]
    # utt2spk     [<uterranceID> <speakerID>]
    # corpus.txt  [<text_transcription>]

    # Making spk2utt files
    ${TOOLS_DIR}/utils/utt2spk_to_spk2utt.pl data/train/utt2spk > data/train/spk2utt
    ${TOOLS_DIR}/utils/utt2spk_to_spk2utt.pl data/test/utt2spk > data/test/spk2utt

    echo
    echo "===== FEATURES EXTRACTION ====="
    echo

    # Making feats.scp files
    mfccdir=mfcc
    # Uncomment and modify arguments in scripts below if you have any problems with data sorting
    # utils/validate_data_dir.sh data/train     # script for checking prepared data - here: for data/train directory
    # utils/fix_data_dir.sh data/train          # tool for data proper sorting if needed - here: for data/train directory
    ${TOOLS_DIR}/steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/train exp/make_mfcc/train $mfccdir
    ${TOOLS_DIR}/steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" data/test exp/make_mfcc/test $mfccdir

    # Making cmvn.scp files
    ${TOOLS_DIR}/steps/compute_cmvn_stats.sh data/train exp/make_mfcc/train $mfccdir
    ${TOOLS_DIR}/steps/compute_cmvn_stats.sh data/test exp/make_mfcc/test $mfccdir

    echo
    echo "===== PREPARING LANGUAGE DATA ====="
    echo

    # Needs to be prepared by hand (or using self written scripts):
    #
    # lexicon.txt           [<word> <phone 1> <phone 2> ...]
    # nonsilence_phones.txt    [<phone>]
    # silence_phones.txt    [<phone>]
    # optional_silence.txt  [<phone>]

    # Preparing language data
    ${TOOLS_DIR}/utils/prepare_lang.sh data/local/dict "<UNK>" data/local/lang data/lang

    echo
    echo "===== LANGUAGE MODEL CREATION ====="
    echo "===== MAKING lm.arpa ====="
    echo

    loc=`which ngram-count`;
    if [ -z $loc ]; then
       if uname -a | grep 64 >/dev/null; then
               sdir=$KALDI_ROOT/tools/srilm/bin/i686-m64
       else
                       sdir=$KALDI_ROOT/tools/srilm/bin/i686
       fi
       if [ -f $sdir/ngram-count ]; then
                       echo "Using SRILM language modelling tool from $sdir"
                       export PATH=$PATH:$sdir
       else
                       echo "SRILM toolkit is probably not installed.
                               Instructions: tools/install_srilm.sh"
                       exit 1
       fi
    fi

    local=data/local
    mkdir $local/tmp
    ngram-count -order $lm_order -write-vocab $local/tmp/vocab-full.txt -wbdiscount -text $local/corpus.txt -lm $local/tmp/lm.arpa

    echo
    echo "===== MAKING G.fst ====="
    echo

    lang=data/lang
    arpa2fst --disambig-symbol=0 --read-symbol-table=$lang/words.txt $local/tmp/lm.arpa $lang/G.fst

    echo
    echo "===== MONO TRAINING ====="
    echo

    steps/train_mono.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono  || exit 1


    echo
    echo "===== MONO DECODING ====="
    echo

    utils/mkgraph.sh --mono data/lang exp/mono exp/mono/graph || exit 1
    steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/mono/graph data/test exp/mono/decode

    echo
    echo "===== MONO ALIGNMENT ====="
    echo

    steps/align_si.sh --nj $nj --cmd "$train_cmd" data/train data/lang exp/mono exp/mono_ali || exit 1

    echo
    echo "===== TRI1 (first triphone pass) TRAINING ====="
    echo

    steps/train_deltas.sh --cmd "$train_cmd" 2000 11000 data/train data/lang exp/mono_ali exp/tri1 || exit 1

    echo
    echo "===== TRI1 (first triphone pass) DECODING ====="
    echo

    utils/mkgraph.sh data/lang exp/tri1 exp/tri1/graph || exit 1
    steps/decode.sh --config conf/decode.config --nj $nj --cmd "$decode_cmd" exp/tri1/graph data/test exp/tri1/decode

    echo
    echo "===== run.sh script is finished ====="
    echo
}

main