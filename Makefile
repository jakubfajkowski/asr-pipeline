SHELL := /bin/bash

$(info Including settings file.)
include settings.mk

ifndef config
    $(error No config file specified!)
endif

$(info Including config file: $(config))
include $(config)
export

# Concrete build variables:
build_dir = "${BUILDS_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
corpus_dir = "${CORPORA_DIR}/${CORPUS_LANG}/${CORPUS_NAME}"
lang=$(shell echo ${CORPUS_LANG} | cut -d '-' -f1)
spk2gender = "$(build_dir)/spk2gender"
text = "$(build_dir)/text"
wav.scp = "$(build_dir)/wav.scp"
words = "$(build_dir)/words"
words_g2p = "$(build_dir)/words_g2p"

$(info $(lang))


all: clean audio_data text_data


clean:
	@ run.sh "Cleaning build directory: $(build_dir)" \
	  rm -rf $(build_dir)


audio_data: build_dir audio_split spk2gender wav.scp


audio_split:
	@ run.sh "Splitting audio data to test and train sets..." \
	  split_data.py "${corpus_dir}/*/*.wav" "${build_dir}" "${SPLIT_RATIO}"


spk2gender:
	@ run.sh "Generating speaker to gender mapping..." \
	  prepare_spk2gender.py "${corpus_dir}/*" "${build_dir}"

wav.scp:
	@ run.sh "Generating utterance id to wav file mapping..." \
	  prepare_wav_scp.py "${corpus_dir}/*/*.wav" "${build_dir}"


text_data: build_dir words_g2p


build_dir:
	@ run.sh "Build directory is: ${build_dir}" \
	  mkdir -p ${build_dir}


words_g2p: words
	@ run.sh "Generating grapheme to phoneme mapping..." \
	  ${TOOLS_DIR}/multilingual-g2p/g2p.sh -w ${words} -l ${lang} > ${words_g2p}


words: text
	@ run.sh "Tokenizing words used in utterances..." \
	  prepare_words.py "${text}" "${build_dir}"


text:
	@ run.sh "Joining all text files..." \
	  prepare_text.py "${corpus_dir}/*/*.transcription.tsv" "${build_dir}"

.PHONY: all        \
        clean      \
        build_dir  \
        audio_data \
		text_data