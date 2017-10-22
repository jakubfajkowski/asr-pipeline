MAKE_PID := $(shell echo $$PPID)
JOB_FLAG := $(filter -j%, $(subst -j ,-j,$(shell ps T | grep "^\s*$(MAKE_PID).*$(MAKE)")))
JOBS     := $(subst -j,,$(JOB_FLAG))
SHELL := /bin/bash

$(info Including settings file.)
include settings.cfg

ifndef config
    $(error No config file specified!)
endif

$(info Including config file: $(config))
include $(config)
export


$(info Language: $(lang))
$(info Version: $(version))

build_dir := $(BUILDS_DIR)/$(lang)/$(corpus_audio_name)
corpus_audio_dir := $(CORPORA_AUDIO_DIR)/$(lang)/$(corpus_audio_name)

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
export PATH := $(shell find src -type d -printf "%p:"):$(PATH)

train_cmd := utils/run.pl
decode_cmd := utils/run.pl


prepare: data local lang
	log.sh -dnt "Ready for training!"

dirs:
	mkdir -p $(data_dir)
	mkdir -p $(train_dir)
	mkdir -p $(test_dir)
	mkdir -p $(local_dir)
	mkdir -p $(lang_dir)
	mkdir -p $(dict_dir)

########################################################################################################################
# DATA DIR
########################################################################################################################
data: $(train_dir) $(test_dir)
split:
	run.sh "Splitting corpus data to test and train sets..." \
	make_split.py -d $(data_dir) -s $(split_ratio) $(corpus_audio_dir)/*

$(data_dir)/%: $(spk2gender) $(wav_scp) $(text) $(words) $(lexicon) $(utt2spk) $(spk2utt)
	steps/make_mfcc.sh --nj 1 $@ $@/log $@/features
	steps/compute_cmvn_stats.sh $@ $@/log $@/features
	utils/fix_data_dir.sh $@

$(spk2gender): $(train_dir)/$(spk2gender) $(test_dir)/$(spk2gender)
$(data_dir)/%/$(spk2gender): split
	run.sh "Generating speaker to gender mapping..." \
	make_spk2gender.py "$(dir $@)/[MF]???" > $@

$(wav_scp): $(train_dir)/$(wav_scp) $(test_dir)/$(wav_scp)
$(data_dir)/%/$(wav_scp): split
	run.sh "Generating utterance id to wav file mapping..." \
	make_wav_scp.py "$(dir $@)/*/*.wav" > $@

$(text): $(train_dir)/$(text) $(test_dir)/$(text)
$(data_dir)/%/$(text): split
	run.sh "Joining all text files..." \
	make_text.sh "$(dir $@)/*/*transcription.tsv" > $@

$(words): $(train_dir)/$(words) $(test_dir)/$(words)
$(data_dir)/%/$(words): $(data_dir)/%/$(text)
	run.sh "Tokenizing words used in utterances..." \
	make_words.py "$(dir $@)/$(text)" > $@

$(lexicon): $(train_dir)/$(lexicon) $(test_dir)/$(lexicon)
$(data_dir)/%/$(lexicon): $(data_dir)/%/$(words)
	run.sh "Generating grapheme to phoneme mapping..." \
	make_data_lexicon.sh "$(dir $@)/$(words)" > $@

$(utt2spk): $(train_dir)/$(utt2spk) $(test_dir)/$(utt2spk)
$(data_dir)/%/$(utt2spk): split
	run.sh "Preparing utt2spk..." \
	make_utt2spk.sh "$(dir $@)" > $@

$(spk2utt): $(train_dir)/$(spk2utt) $(test_dir)/$(spk2utt)
$(data_dir)/%/$(spk2utt): $(data_dir)/%/$(utt2spk)
	run.sh "Preparing spk2utt..." \
	utils/utt2spk_to_spk2utt.pl "$(dir $@)/$(utt2spk)" > $@

########################################################################################################################
# LOCAL DIR
########################################################################################################################
local: $(dict_dir)

$(corpus): $(local_dir)/$(corpus)
$(local_dir)/$(corpus):
	run.sh "Preparing corpus..." \
	make_corpus.sh "$(corpus_audio_dir)/*/*transcription.tsv" > $@

$(local_dir)/lm.arpa: $(corpus)
	ngram-count -order 1 -wbdiscount -text "$(local_dir)/corpus.txt" -lm "$(local_dir)/lm.arpa"

$(dict_dir): $(silence_phones) $(optional_silence) $(nonsilence_phones) $(lexicon) $(local_dir)/lm.arpa

$(silence_phones): $(dict_dir)/$(silence_phones)
$(dict_dir)/$(silence_phones):
	run.sh "Preparing silence phones..." \
	make_silence_phones.sh > $@

$(optional_silence): $(dict_dir)/$(optional_silence)
$(dict_dir)/$(optional_silence):
	run.sh "Preparing optional silence..." \
	make_optional_silence.sh > $@

$(nonsilence_phones): $(dict_dir)/$(nonsilence_phones)
$(dict_dir)/$(nonsilence_phones):
	run.sh "Preparing nonsilence phones..." \
	make_nonsilence_phones.sh "$(data_dir)" > $@

$(lexicon): $(dict_dir)/$(lexicon)
$(dict_dir)/$(lexicon): $(test_dir)/$(lexicon) $(train_dir)/$(lexicon)
	run.sh "Preparing lexicon..." \
	make_local_lexicon.sh "$(data_dir)" > $@

########################################################################################################################
# LANG DIR
########################################################################################################################
lang: $(local_dir) $(lang_dir)/G.fst

lang-preparation:
	utils/prepare_lang.sh "$(local_dir)/dict" "<UNK>" "$(local_dir)/lang" "$(lang_dir)"
	
$(lang_dir)/G.fst: lang-preparation
	arpa2fst --disambig-symbol="#0" --read-symbol-table="$(lang_dir)/words.txt" "$(local_dir)/lm.arpa" "$(lang_dir)/G.fst"

########################################################################################################################
# EXP DIR
########################################################################################################################
mono-model:
#	train_mono.sh --nj 4 --cmd "$(train_cmd)" --totgauss 400 \
#	$(train_dir) $(lang_dir) $(build_dir)/exp/mono
#
#	mkgraph.sh $(lang_dir) $(exp_dir)/mono $(exp_dir)/mono/graph
#
#	decode_offline.sh --nj 1 --cmd "$(decode_cmd)" --skip-scoring true \
#	$(exp_dir)/mono/graph $(test_dir) $(build_dir)/exp/mono/offline
#
#	score_kaldi_wer.sh --cmd "$(decode_cmd)" \
#	$(test_dir) $(exp_dir)/mono/graph $(build_dir)/exp/mono/offline
#
#	prepare_online_decoding.sh $(train_dir) $(lang_dir) $(exp_dir)/mono $(build_dir)/exp/mono/online

	decode_online.sh --nj 1 --cmd "$(decode_cmd)" --skip-scoring true \
	$(exp_dir)/mono/graph $(test_dir) $(build_dir)/exp/mono/online

	score_kaldi_wer.sh --cmd "$(decode_cmd)" \
	$(test_dir) $(exp_dir)/mono/graph $(build_dir)/exp/mono/online

clean:
	rm -rf $(build_dir)


.PHONY: prepare    \
        clean      \
        mono-model \
        split