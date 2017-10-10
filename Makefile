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

corpus_dir := $(CORPORA_DIR)/$(corpus_lang)/$(corpus_name)
build_dir := $(BUILDS_DIR)/$(corpus_name)/$(corpus_name)

exp_dir := $(build_dir)/exp
data_dir := $(build_dir)/data
test_dir := $(data_dir)/test
train_dir := $(data_dir)/train
mfcc_dir := $(build_dir)/mfcc
lang_dir := $(build_dir)/lang
local_dir := $(build_dir)/local

build: $(data_dir) $(local_dir) $(mfcc_dir) $(lang_dir) $(exp_dir)
	echo $@

$(data_dir): $(test_dir) $(train_dir)
	echo $@

$(local_dir):
	echo $@

$(mfcc_dir): $(data_dir)
	echo $@

$(lang_dir): $(data_dir)
	echo $@

$(exp_dir): $(data_dir) $(local_dir) $(mfcc_dir) $(lang_dir)
	echo $@

$(data_dir)/%:
	echo $@


clean:
	@ run.sh "Cleaning build directory: $(build_dir)" \
	  rm -rf $(build_dir)


.PHONY: build        \
        clean