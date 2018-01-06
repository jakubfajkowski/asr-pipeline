#!/usr/bin/env bash

train_dir=${1}; shift
test_dir=${1}; shift
lang_dir=${1}; shift
model_dir=${1}; shift

steps/decode.sh --nj 4 --skip-scoring true \
${model_dir}/graph ${test_dir} ${model_dir}/offline
steps/score_kaldi.sh \
${test_dir} ${model_dir}/graph ${model_dir}/offline

steps/online/prepare_online_decoding.sh ${train_dir} ${lang_dir} ${model_dir} ${model_dir}
steps/online/decode.sh --nj 4 --skip-scoring true \
${model_dir}/graph ${test_dir} ${model_dir}/online
steps/score_kaldi.sh \
${test_dir} ${model_dir}/graph ${model_dir}/online