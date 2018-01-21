#!/usr/bin/env bash

source path.sh

local_dir=${1}
data_dir=${2}

corpus=${data_dir}/corpus.txt
corpus_rules=${local_dir}/corpus.rules
dirty_corpus=${data_dir}/corpus.txt~
lexicon=${data_dir}/lexicon.txt
lexicon_rules=${local_dir}/lexicon.rules
spk2utt=${data_dir}/spk2utt
text=${data_dir}/text
utt2spk=${data_dir}/utt2spk
wav_scp=${data_dir}/wav.scp
words=${data_dir}/words.txt

local/processing/wav_scp.sh ${data_dir}/*/*.wav > ${wav_scp}

local/processing/text.sh ${lang} ${data_dir}/*/*transcription.tsv > ${text}

local/processing/utt2spk.sh ${data_dir}/*/*.wav > ${utt2spk}

utils/utt2spk_to_spk2utt.pl ${utt2spk} > ${spk2utt}

< ${text} cut -f 2 > ${dirty_corpus}
< ${dirty_corpus} local/processing/corpus.sh ${lang} ${corpus_rules} > ${corpus}
if ${cheat} || ! [ -s ${local_dir}/corpus.txt~ ]; then
    cat ${corpus} >> ${local_dir}/corpus.txt
fi

< ${corpus} local/processing/words.sh ${lang} > ${words}

< ${words} local/processing/lexicon.sh ${lang} ${lexicon_rules} > ${lexicon}

case ${feature_type} in
    fbank)
        steps/make_fbank.sh --nj ${jobs} ${data_dir} ${data_dir}/log ${data_dir}
        ;;
    mfcc)
        steps/make_mfcc.sh --nj ${jobs} ${data_dir} ${data_dir}/log ${data_dir}
        ;;
    plp)
        steps/make_plp.sh --nj ${jobs} ${data_dir} ${data_dir}/log ${data_dir}
        ;;
esac

steps/compute_cmvn_stats.sh ${data_dir} ${data_dir}/log ${data_dir}

utils/fix_data_dir.sh ${data_dir}
