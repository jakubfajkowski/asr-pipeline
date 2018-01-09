export JOBS       := 4

export BUILDS_DIR := ./builds
export TARGET_DIR := ./scripts/target
export SRILM_DIR :=  /home/jfajkowski/Projects/kaldi/tools/srilm

export PATH := $(PWD):$(PATH)
export PATH := $(TARGET_DIR):$(PATH)
export PATH := $(SRILM_DIR)/bin:$(SRILM_DIR)/bin/i686-m64:$(PATH)