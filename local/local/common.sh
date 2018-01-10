#!/usr/bin/env bash

source path.sh

local_dir=${1}

corpus=${local_dir}/corpus.txt
corpus_rules=${local_dir}/../corpus.rules
dirty_corpus=${local_dir}/corpus.txt~
lexicon=${local_dir}/lexicon.txt
lexicon_rules=${local_dir}/../lexicon.rules
nonsilence_phones=${local_dir}/nonsilence_phones.txt
optional_silence=${local_dir}/optional_silence.txt
silence_phones=${local_dir}/silence_phones.txt
words=${local_dir}/words.txt


< ${dirty_corpus} local/processing/corpus.sh ${lang} ${corpus_rules} >> ${corpus}

< ${corpus} local/processing/words.sh ${lang} > ${words}

echo -e "<UNK>\tSPN" > ${lexicon}
< ${words} local/processing/lexicon.sh ${lang} ${lexicon_rules} >> ${lexicon}

local/processing/silence_phones.sh > ${silence_phones}

local/processing/optional_silence.sh > ${optional_silence}

local/processing/nonsilence_phones.sh ${silence_phones} ${lexicon} > ${nonsilence_phones}