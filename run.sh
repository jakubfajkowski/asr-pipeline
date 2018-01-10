#!/usr/bin/env bash

set -e
source path.sh
source settings.sh
source utils.sh

recipe=${1}

source ${recipe}

build_dir=${BUILDS_DIR}/${lang}/${version}
data_dir=${build_dir}/data
info_dir=${build_dir}/info
lang_dir=${build_dir}/lang
local_dir=${build_dir}/local
model_dir=${build_dir}/model

create() {
    execute "Build directory is: ${build_dir}" \
    mkdir -p ${build_dir}

    mkdir -p ${build_dir}
    mkdir -p ${data_dir}
    mkdir -p ${info_dir}
    mkdir -p ${lang_dir}
    mkdir -p ${local_dir}
    mkdir -p ${model_dir}
}

copy_data() {
    cp -r ${corpus_data}/* ${data_dir}
	cp -r ${corpus_local}/* ${local_dir}
	cp ${recipe} ${build_dir}/recipe.mk
}

process_data_sub_dirs() {
    for data_sub_dir in ${data_dir}/*; do
        if [ -d ${data_sub_dir} ]; then
            local/data/common.sh ${data_sub_dir} ${local_dir}
        fi
    done
}

process_local_sub_dirs() {
    for local_sub_dir in ${local_dir}/*; do
        if [ -d ${local_sub_dir} ]; then
            local/local/common.sh ${local_sub_dir} ${local_dir}
        fi
    done
}

process_lang_sub_dirs() {
    for local_sub_dir in ${local_dir}/*; do
        if [ -d ${local_sub_dir} ]; then
            lang_sub_dir=${lang_dir}/$(basename ${local_sub_dir})
            local/lang/common.sh ${lang_sub_dir} ${local_sub_dir}
        fi
    done
}

score() {
    mode=${1}
    offline_dir=${2}
    online_dir=${offline_dir}-online

    utils/mkgraph.sh ${base_lang_dir} ${offline_dir} ${offline_dir}/graph

    if [ "${mode}" == "si" ]; then
        steps/decode.sh --nj ${JOBS} ${offline_dir}/graph ${test_dir} ${offline_dir}/decode
    elif [ "${mode}" == "fmllr" ]; then
        steps/decode_fmllr.sh --nj ${JOBS} ${offline_dir}/graph ${test_dir} ${offline_dir}/decode
    elif [ "${mode}" == "online" ]; then
        local/prepare_online_decoding.sh ${train_dir} ${base_lang_dir} ${offline_dir} ${online_dir}
        steps/online/decode.sh --nj ${JOBS} ${online_dir}/graph ${test_dir} ${online_dir}/decode
	fi
}

rescore() {
    mode=${1}
    offline_dir=${2}
    online_dir=${offline_dir}-online
    if [ "${mode}" == "si" ] || [ "${mode}" == "fmllr" ]; then
        steps/lmrescore.sh ${base_lang_dir} ${rescore_lang_dir} ${test_dir} ${online_dir}/decode ${offline_dir}/rescore
    elif [ "${mode}" == "online" ]; then
        steps/lmrescore.sh ${base_lang_dir} ${rescore_lang_dir} ${test_dir} ${online_dir}/decode ${online_dir}/rescore
	fi
}

#create
#copy_data
#process_data_sub_dirs
#process_local_sub_dirs
#process_lang_sub_dirs
train
