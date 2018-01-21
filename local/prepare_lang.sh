#!/usr/bin/env bash

source path.sh

ngram_order=${1}
local_dir=${2}
lang_dir=${3}

corpus=${local_dir}/corpus.txt
lm_arpa=${lang_dir}/lm.arpa
lm_fst=${lang_dir}/G.fst
words=${lang_dir}/words.txt


utils/prepare_lang.sh ${local_dir} "<UNK>" ${local_dir}/tmp ${lang_dir}

local/processing/lm_arpa.sh ${ngram_order} ${corpus} > ${lm_arpa}

local/processing/lm_fst.sh ${words} ${lm_arpa} > ${lm_fst}
