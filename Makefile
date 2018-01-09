SHELL := /bin/bash

include settings.mk
include $(recipe)

########################################################################################################################
# DIRECTORIES
########################################################################################################################
build_dir := $(BUILDS_DIR)/$(lang)/$(version)
model_dir := $(build_dir)/model
ali_dir   := $(build_dir)/ali
data_dir  := $(build_dir)/data
test_dir  := $(data_dir)/test
train_dir := $(data_dir)/train
lang_dir  := $(build_dir)/lang
local_dir := $(data_dir)/local

########################################################################################################################
# FILES
########################################################################################################################
corpus            := corpus.txt
corpus_rules      := corpus.rules
lexicon           := lexicon.txt
lexicon_rules     := lexicon.rules
lm_arpa           := lm.arpa
lm_fst            := G.fst
nonsilence_phones := nonsilence_phones.txt
optional_silence  := optional_silence.txt
silence_phones    := silence_phones.txt
spk2utt           := spk2utt
text              := text
utt2spk           := utt2spk
wav_scp           := wav.scp
words             := words.txt

########################################################################################################################
# MODELS DIRECTORIES
########################################################################################################################
mono_dir := $(model_dir)/mono
online_mono_dir := $(model_dir)/online-mono
tri1_dir := $(model_dir)/tri1
online_tri1_dir := $(model_dir)/online-tri1
tri2_dir := $(model_dir)/tri2
online_tri2_dir := $(model_dir)/online-tri2
tri3_dir := $(model_dir)/tri3
online_tri3_dir := $(model_dir)/online-tri3
tri4_dir := $(model_dir)/tri4
online_tri4_dir := $(model_dir)/online-tri4
nnet_dir := $(model_dir)/nnet

########################################################################################################################
# ALIGNMENTS DIRECTORIES
########################################################################################################################
mono_ali_dir := $(ali_dir)/mono
tri1_ali_dir := $(ali_dir)/tri1
tri2_ali_dir := $(ali_dir)/tri2
tri3_ali_dir := $(ali_dir)/tri3
tri4_ali_dir := $(ali_dir)/tri4

########################################################################################################################
# TARGETS
########################################################################################################################
all: initialize features language-model | model

clean:
	rm -rf $(build_dir)

$(build_dir)/%:
	mkdir -p $@

initialize: $(train_dir) $(test_dir) $(local_dir)
	cp -r $(corpus_train)/* $(train_dir)
	cp -r $(corpus_test)/* $(test_dir)
	cp -r $(corpus_local)/* $(local_dir)

########################################################################################################################
# DATA DIR
########################################################################################################################
data: $(wav_scp) $(text) $(utt2spk) $(spk2utt) | $(data_dir)

$(wav_scp): $(train_dir)/$(wav_scp) $(test_dir)/$(wav_scp)
$(data_dir)/%/$(wav_scp):
	execute.sh                                  \
	    message:     'Creating $@'              \
	    command:     'wav_scp.sh $(@D)/*/*.wav' \
	    input-file:  ''                         \
	    output-file: '$@'

$(text): $(train_dir)/$(text) $(test_dir)/$(text)
$(data_dir)/%/$(text):
	execute.sh                                                    \
	    message:     'Creating $@'                                \
	    command:     'text.sh $(lang) $(@D)/*/*transcription.tsv' \
	    input-file:  ''                                           \
	    output-file: '$@'

$(utt2spk): $(train_dir)/$(utt2spk) $(test_dir)/$(utt2spk)
$(data_dir)/%/$(utt2spk):
	execute.sh                                  \
	    message:     'Creating $@'              \
	    command:     'utt2spk.sh $(@D)/*/*.wav' \
	    input-file:  ''                         \
	    output-file: '$@'

$(spk2utt): $(train_dir)/$(spk2utt) $(test_dir)/$(spk2utt)
$(data_dir)/%/$(spk2utt): $(data_dir)/%/$(utt2spk)
	execute.sh                                                      \
	    message:     'Creating $@'                                  \
	    command:     'utils/utt2spk_to_spk2utt.pl $(@D)/$(utt2spk)' \
	    input-file:  ''                                             \
	    output-file: '$@'


#########################################################################################################################
## LOCAL DIR
#########################################################################################################################
local: $(corpus) $(words) $(lexicon) $(silence_phones) $(optional_silence) $(nonsilence_phones) | $(local_dir) $(local_dir)


$(corpus): $(local_dir)/$(corpus)
$(local_dir)/$(corpus): $(train_dir)/$(corpus) $(test_dir)/$(corpus)
	execute.sh                                                                                      \
	    message:     'Creating $@'                                                                  \
	    command:     'local_corpus.sh $(lang) $(local_dir)/$(corpus_rules) $(data_dir)/*/$(corpus)' \
	    input-file:  '$@~'                                                                          \
	    output-file: '$@'
$(data_dir)/%/$(corpus): $(train_dir)/$(text) $(test_dir)/$(text)
	execute.sh                                              \
	    message:     'Creating $@'                          \
	    command:     'data_corpus.sh $(lang) $(local_dir)/$(corpus_rules) $(@D)/$(text)' \
	    input-file:  ''                                     \
	    output-file: '$@'


$(words): $(local_dir)/$(words)
$(local_dir)/$(words): $(train_dir)/$(words) $(test_dir)/$(words) $(local_dir)/$(corpus)
	execute.sh                                                       \
	    message:     'Creating $@'                                   \
	    command:     'local_words.sh $(lang) $(data_dir)/*/$(words)' \
	    input-file:  '$(local_dir)/$(corpus)'                        \
	    output-file: '$@'
$(data_dir)/%/$(words): $(data_dir)/%/$(corpus)
	execute.sh                                               \
	    message:     'Creating $@'                           \
	    command:     'data_words.sh $(lang) $(@D)/$(corpus)' \
	    input-file:  ''                                      \
	    output-file: '$@'


$(lexicon): $(local_dir)/$(lexicon)
$(local_dir)/$(lexicon): $(train_dir)/$(lexicon) $(test_dir)/$(lexicon) $(local_dir)/$(words)
	execute.sh                                                                                        \
	    message:     'Creating $@'                                                                    \
	    command:     'local_lexicon.sh $(lang) $(local_dir)/$(lexicon_rules) $(data_dir)/*/$(lexicon)' \
	    input-file:  '$(local_dir)/$(words)'                                                          \
	    output-file: '$@'
$(data_dir)/%/$(lexicon): $(data_dir)/%/$(words)
	execute.sh                                                                             \
	    message:     'Creating $@'                                                         \
	    command:     'data_lexicon.sh $(lang) $(local_dir)/$(lexicon_rules) $(@D)/$(words)' \
	    input-file:  ''                                                                    \
	    output-file: '$@'


phones: $(silence_phones) $(optional_silence) $(nonsilence_phones)
$(silence_phones): $(local_dir)/$(silence_phones)
$(local_dir)/$(silence_phones):
	execute.sh                           \
	    message:     'Creating $@'       \
	    command:     'silence_phones.sh' \
	    input-file:  ''                  \
	    output-file: '$@'
$(optional_silence): $(local_dir)/$(optional_silence)
$(local_dir)/$(optional_silence):
	execute.sh                             \
	    message:     'Creating $@'         \
	    command:     'optional_silence.sh' \
	    input-file:  ''                    \
	    output-file: '$@'
$(nonsilence_phones): $(local_dir)/$(nonsilence_phones)
$(local_dir)/$(nonsilence_phones): $(local_dir)/$(silence_phones) $(local_dir)/$(lexicon)
	execute.sh                                                                                   \
	    message:     'Creating $@'                                                               \
	    command:     'nonsilence_phones.sh $(local_dir)/$(silence_phones) $(local_dir)/$(lexicon)' \
	    input-file:  ''                                                                          \
	    output-file: '$@'


########################################################################################################################
# LANG DIR
########################################################################################################################
lang: $(lang_dir)

$(lang_dir): local
	mkdir -p $(lang_dir)
	execute.sh                                                                \
	message:     'Creating $@'                                                    \
	command:     'utils/prepare_lang.sh $(local_dir) <UNK> $(local_dir)/lang $@'

#########################################################################################################################
## FEATURE EXTRACTION
#########################################################################################################################
features: data
	execute.sh                                                           \
	message:     'Extracting $(feature_type) features'                   \
	command:     'feature_extraction.sh $(JOBS) $(feature_type) $(data_dir)'

#########################################################################################################################
## LANGUAGE MODELLING
#########################################################################################################################
language-model: $(lang_dir) $(local_dir)/$(corpus)
	execute.sh                                                          \
	    message:     'Creating $@'                                      \
	    command:     'lm_arpa.sh $(ngram_order) $(local_dir)/$(corpus)' \
	    input-file:  ''                                                 \
	    output-file: '$(lang_dir)/$(lm_arpa)'

	execute.sh                                          \
		message:     'Creating $@'                      \
		command:     'lm_fst.sh $(lang_dir)/$(words) $(lang_dir)/$(lm_arpa)' \
		input-file:  ''                                 \
		output-file: '$(lang_dir)/$(lm_fst)'

#########################################################################################################################
## MODELS
#########################################################################################################################
model: $(model_type)

mono: train-mono score-mono
train-mono: $(mono_dir)
$(mono_dir): 
	execute.sh                            \
		message:     'Training monophone' \
		command:     'steps/train_mono.sh --nj $(JOBS) $(train_dir) $(lang_dir) $(mono_dir)'
online-mono: train-online-mono score-online-mono
train-online-mono: $(online_mono_dir)
$(online_mono_dir): $(mono_dir)
	execute.sh                          \
		message:     'Online monophone' \
		command:     'scripts/prepare_online_decoding.sh $(train_dir) $(lang_dir) $(mono_dir) $(online_mono_dir)'
align-mono: $(mono_ali_dir)
$(mono_ali_dir): $(mono_dir)
	execute.sh                            \
		message:     'Aligning monophone' \
		command:     'steps/align_si.sh --nj $(JOBS) $(train_dir) $(lang_dir) $(mono_dir) $(mono_ali_dir)'


tri1: train-tri1 score-tri1
train-tri1: $(tri1_dir)
$(tri1_dir): $(mono_ali_dir)
	execute.sh                           \
		message:     'Training triphone (deltas)' \
		command:     'steps/train_deltas.sh $(hidden_states_number) $(gaussians_number) $(train_dir) $(lang_dir) $(mono_ali_dir) $(tri1_dir)'
online-tri1: train-online-tri1 score-online-tri1
train-online-tri1: $(online_tri1_dir)
$(online_tri1_dir): $(tri1_dir)
	execute.sh                         \
		message:     'Online triphone (deltas)' \
		command:     'scripts/prepare_online_decoding.sh $(train_dir) $(lang_dir) $(tri1_dir) $(online_tri1_dir)'
align-tri1: $(tri1_ali_dir)
$(tri1_ali_dir): $(tri1_dir)
	execute.sh                           \
		message:     'Aligning triphone (deltas)' \
		command:     'steps/align_si.sh --nj $(JOBS) --use-graphs true $(train_dir) $(lang_dir) $(tri1_dir) $(tri1_ali_dir)'


tri2: train-tri2 score-tri2
train-tri2: $(tri2_dir)
$(tri2_dir): $(tri1_ali_dir)
	execute.sh                           \
		message:     'Training triphone (deltas and delta-deltas)' \
		command:     'steps/train_deltas.sh $(hidden_states_number) $(gaussians_number) $(train_dir) $(lang_dir) $(tri1_ali_dir) $(tri2_dir)'
online-tri2: train-online-tri2 score-online-tri2
train-online-tri2: $(online_tri2_dir)
$(online_tri2_dir): $(tri2_dir)
	execute.sh                         \
		message:     'Online triphone (deltas and delta-deltas)' \
		command:     'scripts/prepare_online_decoding.sh $(train_dir) $(lang_dir) $(tri2_dir) $(online_tri2_dir)'
align-tri2: $(tri2_ali_dir)
$(tri2_ali_dir): $(tri2_dir)
	execute.sh                           \
		message:     'Aligning triphone (LDA and MLLT)' \
		command:     'steps/align_si.sh --nj $(JOBS) --use-graphs true $(train_dir) $(lang_dir) $(tri2_dir) $(tri2_ali_dir)'


tri3: train-tri3 score-tri3
train-tri3: $(tri3_dir)
$(tri3_dir): $(tri2_ali_dir)
	execute.sh                           \
		message:     'Training triphone (LDA and MLLT)' \
		command:     'steps/train_lda_mllt.sh $(hidden_states_number) $(gaussians_number) $(train_dir) $(lang_dir) $(tri1_ali_dir) $(tri3_dir)'
online-tri3: train-online-tri3 score-online-tri3
train-online-tri3: $(online_tri3_dir)
$(online_tri3_dir): $(tri3_dir)
	execute.sh                         \
		message:     'Online triphone (LDA and MLLT)' \
		command:     'scripts/prepare_online_decoding.sh $(train_dir) $(lang_dir) $(tri3_dir) $(online_tri3_dir)'
align-tri3: $(tri3_ali_dir)
$(tri3_ali_dir): $(tri3_dir)
	execute.sh                           \
		message:     'Aligning triphone (LDA and MLLT)' \
		command:     'steps/align_si.sh --nj $(JOBS) --use-graphs true $(train_dir) $(lang_dir) $(tri3_dir) $(tri3_ali_dir)'


tri4: train-tri4 score-tri4
train-tri4: $(tri4_dir)
$(tri4_dir): $(tri3_ali_dir)
	execute.sh                           \
		message:     'Training triphone (SAT)' \
		command:     'steps/train_sat.sh $(hidden_states_number) $(gaussians_number) $(train_dir) $(lang_dir) $(tri3_ali_dir) $(tri4_dir)'
online-tri4: train-online-tri4 score-online-tri4
train-online-tri4: $(online_tri4_dir)
$(online_tri4_dir): $(tri4_dir)
	execute.sh                         \
		message:     'Online triphone (SAT)' \
		command:     'scripts/prepare_online_decoding.sh $(train_dir) $(lang_dir) $(tri4_dir) $(online_tri4_dir)'

clean-%:
	@echo "rm -rf $(model_dir)/$(@:clean-%=%)"

graph-%: train-%
	execute.sh                                         \
		message:     'Making graph for $(@:graph-%=%)' \
		command:     'utils/mkgraph.sh $(lang_dir) $(model_dir)/$(@:graph-%=%) $(model_dir)/$(@:graph-%=%)/graph'

score-%: graph-%
	execute.sh                                 \
		message:     'Decoding $(@:score-%=%)' \
	    command:     'steps/decode.sh --nj $(JOBS) --skip-scoring true $(model_dir)/$(@:score-%=%)/graph $(test_dir) $(model_dir)/$(@:score-%=%)/decode'
	execute.sh                                \
		message:     'Scoring $(@:score-%=%)' \
		command:     'steps/score_kaldi.sh $(test_dir) $(model_dir)/$(@:score-%=%)/graph $(model_dir)/$(@:score-%=%)/decode'

score-online-%: graph-online-%
	execute.sh                                 \
		message:     'Decoding $(@:score-%=%)' \
	    command:     'steps/online/decode.sh --nj $(JOBS) --skip-scoring true $(model_dir)/$(@:score-%=%)/graph $(test_dir) $(model_dir)/$(@:score-%=%)/decode'
	execute.sh                                \
		message:     'Scoring $(@:score-%=%)' \
		command:     'steps/score_kaldi.sh $(test_dir) $(model_dir)/$(@:score-%=%)/graph $(model_dir)/$(@:score-%=%)/decode'

.PHONY: all        \
        clean      \
        data       \
        features   \
        initialize \
        local
