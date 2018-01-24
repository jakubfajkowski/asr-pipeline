#!/usr/bin/env bash

source path.sh

format=${1}
ngram_order=${2}
local_dir=${3}
lang_dir=${4}

corpus=${local_dir}/corpus.txt
lm_arpa=${lang_dir}/lm.arpa
lm_carpa=${lang_dir}/G.carpa
lm_fst=${lang_dir}/G.fst
words=${lang_dir}/words.txt


utils/prepare_lang.sh ${local_dir} "<UNK>" ${local_dir}/tmp ${lang_dir}

local/processing/lm_arpa.sh ${ngram_order} ${corpus} > ${lm_arpa}

if [ ${format} == "fst" ]; then
    local/processing/lm_fst.sh ${words} ${lm_arpa} > ${lm_fst}
elif [ ${format} == "carpa" ]; then
    local/processing/lm_carpa.sh ${words} ${lm_arpa} > ${lm_carpa}
fi