#!/usr/bin/env bash

export cheat=true

export lang=pl-PL
export version=0.0.1
export ngram_order=3

export corpus_data=/home/${USER}/Documents/ASR/empty/data
export corpus_local=/home/${USER}/Documents/ASR/empty/local

export base_lm=base
export rescore_lm=rescore

# Available feature types: fbank, mfcc, plp.
export feature_type=mfcc

export hidden_states_number=64
export gaussians_number=512


train() {
    train_dir=${data_dir}/train
    test_dir=${data_dir}/test
    base_lang_dir=${lang_dir}/base
    rescore_lang_dir=${lang_dir}/rescore

    log -int "Training monophone model."
    steps/train_mono.sh --nj ${JOBS} ${train_dir} ${base_lang_dir} ${model_dir}/mono
    steps/align_si.sh --nj ${JOBS} ${train_dir} ${base_lang_dir} ${model_dir}/mono ${model_dir}/mono-ali
    score "online" ${model_dir}/mono
    rescore "online" ${model_dir}/mono
    log -dnt "Training monophone model."

    log -int "Training triphone model (deltas)."
    steps/train_deltas.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${base_lang_dir} ${model_dir}/mono-ali ${model_dir}/tri1
    steps/align_si.sh --nj ${JOBS} --use-graphs true ${train_dir} ${base_lang_dir} ${model_dir}/tri1 ${model_dir}/tri1-ali
    score "online" ${model_dir}/tri1
    rescore "online" ${model_dir}/tri1
    log -int "Training triphone model (deltas)."

    log -int "Training triphone model (deltas and delta-deltas)."
    steps/train_deltas.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${base_lang_dir} ${model_dir}/tri1-ali ${model_dir}/tri2
    steps/align_si.sh --nj ${JOBS} --use-graphs true ${train_dir} ${base_lang_dir} ${model_dir}/tri2 ${model_dir}/tri2-ali
    score "online" ${model_dir}/tri2
    rescore "online" ${model_dir}/tri2
    log -dnt "Training triphone model (deltas and delta-deltas)."

    log -int "Training triphone model (LDA and MLLT)."
    steps/train_lda_mllt.sh  ${hidden_states_number} ${gaussians_number} ${train_dir} ${base_lang_dir} ${model_dir}/tri2-ali ${model_dir}/tri3
    steps/align_si.sh --nj ${JOBS} --use-graphs true ${train_dir} ${base_lang_dir} ${model_dir}/tri3 ${model_dir}/tri3-ali
    score "online" ${model_dir}/tri3
    rescore "online" ${model_dir}/tri3
    log -dnt "Training triphone model (LDA and MLLT)."
    
    log -int "Training triphone model (SAT)."
    steps/train_sat.sh ${hidden_states_number} ${gaussians_number} ${train_dir} ${base_lang_dir} ${model_dir}/tri3-ali ${model_dir}/tri4
    score "online" ${model_dir}/tri4
    rescore "online" ${model_dir}/tri4
    log -dnt "Training triphone model (SAT)."
}