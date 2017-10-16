SHELL := /bin/bash

$(info Including settings file.)
include settings.cfg

ifndef config
    $(error No config file specified!)
endif

$(info Including config file: $(config))
include $(config)
export


$(info Language: $(corpus_lang))
$(info Version: $(version))

build_dir := $(BUILDS_DIR)/$(corpus_lang)/$(corpus_name)
corpus_dir := $(CORPORA_DIR)/$(corpus_lang)/$(corpus_name)

exp_dir := $(build_dir)/exp
data_dir := $(build_dir)/data
test_dir := $(data_dir)/test
train_dir := $(data_dir)/train
mfcc_dir := $(build_dir)/mfcc
lang_dir := $(build_dir)/lang
local_dir := $(build_dir)/local
dict_dir := $(local_dir)/dict

corpus = corpus.txt
spk2gender = spk2gender
text := text
wav_scp := wav.scp
words := words
lexicon := lexicon.txt
utt2spk := utt2spk
spk2utt := spk2utt
silence_phones := silence_phones.txt
nonsilence_phones := nonsilence_phones.txt
optional_silence := optional_silence.txt

export LOG := $(build_dir)/LOG
export PATH := src/build:src/processing:src/utils:$(PATH)

train_cmd := utils/run.pl
decode_cmd := utils/run.pl


build: $(data_dir)/ $(local_dir)/ $(lang_dir)/ #$(exp_dir)/
	echo NOT IMPLEMENTED

########################################################################################################################
# DATA DIR
########################################################################################################################
$(data_dir)/: $(train_dir)/ $(test_dir)/ | $(data_dir) split
split: | $(data_dir)
	run.sh "Splitting corpus data to test and train sets..." \
	make_split.py -d $(data_dir) -s $(split_ratio) $(corpus_dir)/*

$(data_dir)/%/: $(spk2gender) $(wav_scp) $(text) $(words) $(lexicon) $(utt2spk) $(spk2utt) | $(train_dir) $(test_dir) split
	steps/make_mfcc.sh --nj 1 $@ $@/log $@/features
	steps/compute_cmvn_stats.sh $@ $@/log $@/features
	utils/fix_data_dir.sh $@

$(spk2gender): $(train_dir)/$(spk2gender) $(test_dir)/$(spk2gender) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(spk2gender): | $(train_dir) $(test_dir) split
	run.sh "Generating speaker to gender mapping..." \
	make_spk2gender.py "$(dir $@)/[MF]???" > $@

$(wav_scp): $(train_dir)/$(wav_scp) $(test_dir)/$(wav_scp) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(wav_scp): | $(train_dir) $(test_dir) split
	run.sh "Generating utterance id to wav file mapping..." \
	make_wav_scp.py "$(dir $@)/*/*.wav" > $@

$(text): $(train_dir)/$(text) $(test_dir)/$(text) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(text): | $(train_dir) $(test_dir) split
	run.sh "Joining all text files..." \
	make_text.sh "$(dir $@)/*/*transcription.tsv" > $@

$(words): $(train_dir)/$(words) $(test_dir)/$(words) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(words): | $(train_dir) $(test_dir) split $(text)
	run.sh "Tokenizing words used in utterances..." \
	make_words.py "$(dir $@)/$(text)" > $@

$(lexicon): $(train_dir)/$(lexicon) $(test_dir)/$(lexicon) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(lexicon): | $(train_dir) $(test_dir) split $(words)
	run.sh "Generating grapheme to phoneme mapping..." \
	make_data_lexicon.sh "$(dir $@)/$(words)" > $@

$(utt2spk): $(train_dir)/$(utt2spk) $(test_dir)/$(utt2spk) | $(train_dir) $(test_dir) split
$(data_dir)/%/$(utt2spk): | $(train_dir) $(test_dir) split
	run.sh "Preparing utt2spk..." \
	make_utt2spk.sh "$(dir $@)" > $@
	
$(spk2utt): $(train_dir)/$(spk2utt) $(test_dir)/$(spk2utt) | $(train_dir) $(test_dir) split $(utt2spk)
$(data_dir)/%/$(spk2utt): | $(train_dir) $(test_dir) split $(spk2utt)
	run.sh "Preparing spk2utt..." \
	utils/utt2spk_to_spk2utt.pl "$(dir $@)/$(utt2spk)" > $@
	
########################################################################################################################
# LOCAL DIR
########################################################################################################################
$(local_dir)/: $(dict_dir)/ | $(local_dir)

$(corpus): $(local_dir)/$(corpus) | $(local_dir)
$(local_dir)/$(corpus): | $(local_dir)
	run.sh "Preparing corpus..." \
	make_corpus.sh "$(corpus_dir)/*/*transcription.tsv" > $@

$(local_dir)/lm.arpa: $(corpus) | $(local_dir)
	ngram-count -order 1 -wbdiscount -text "$(local_dir)/corpus.txt" -lm "$(local_dir)/lm.arpa"

$(dict_dir)/: $(silence_phones) $(optional_silence) $(nonsilence_phones) $(lexicon) $(local_dir)/lm.arpa | $(dict_dir)

$(silence_phones): $(dict_dir)/$(silence_phones) | $(dict_dir)
$(dict_dir)/$(silence_phones): | $(dict_dir)
	run.sh "Preparing silence phones..." \
	make_silence_phones.sh > $@

$(optional_silence): $(dict_dir)/$(optional_silence) | $(dict_dir)
$(dict_dir)/$(optional_silence): | $(dict_dir)
	run.sh "Preparing optional silence..." \
	make_optional_silence.sh > $@

$(nonsilence_phones): $(dict_dir)/$(nonsilence_phones) | $(dict_dir)
$(dict_dir)/$(nonsilence_phones): | $(dict_dir)
	run.sh "Preparing nonsilence phones..." \
	make_nonsilence_phones.sh > $@

$(lexicon): $(dict_dir)/$(lexicon) | $(dict_dir)
$(dict_dir)/$(lexicon): | $(dict_dir)
	run.sh "Preparing lexicon..." \
	make_local_lexicon.sh "$(data_dir)" > $@

########################################################################################################################
# LANG DIR
########################################################################################################################
$(lang_dir)/: $(local_dir)/ $(lang_dir)-preparation $(lang_dir)/G.fst | $(lang_dir)

$(lang_dir)-preparation: | $(lang_dir)
	utils/prepare_lang.sh "$(local_dir)/dict" "<UNK>" "$(local_dir)/lang" "$(lang_dir)"
	
$(lang_dir)/G.fst: | $(lang_dir) $(lang_dir)-preparation
	arpa2fst --disambig-symbol="#0" --read-symbol-table="$(lang_dir)/words.txt" "$(local_dir)/lm.arpa" "$(lang_dir)/G.fst"

########################################################################################################################
# EXP DIR
########################################################################################################################
#$(exp_dir)/: $(data_dir)/ $(local_dir)/ $(mfcc_dir)/ $(lang_dir)/ | $(exp_dir)
#	echo "NOT IMPLEMENTED"

$(build_dir)/%:
	mkdir -p $@

clean:
	rm -rf $(build_dir)


.PHONY: build \
        clean \
        split