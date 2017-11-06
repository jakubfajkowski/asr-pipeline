#!/usr/bin/env bash

source $(which log.sh)
source $(which arguments.sh)

SCRIPT_FILE="$(basename ${0})"
SCRIPT_NAME="$(echo ${SCRIPT_FILE} | strip_extension.sh)"

register_optional_argument "--cmd" "cmd" "utils/parallel/run.pl" "how to run jobs"
register_optional_argument "--jobs" "jobs" "4" "number of parallel jobs"
register_optional_argument "--log-dir" "log_dir" "." "logging directory"
register_optional_argument "--config" "config" "conf/cmvn.conf" "config passed to compute-cmvn-stats"
register_positional_argument "data_dir" ""
parse_arguments $@

feats_dir=$(realpath ${data_dir}/feats)
cmvn_dir=$(realpath ${data_dir}/cmvn)

mkdir -p ${feats_dir}
mkdir -p ${cmvn_dir}

check_requirements.sh ${data_dir}/feats.scp ${data_dir}/spk2utt
utils/split_scp.sh ${data_dir}/feats.scp ${jobs}

# add ,p to the input rspecifier so that we can just skip over
# utterances that have bad wave data.
$cmd JOB=1:${jobs} ${log_dir}/${SCRIPT_NAME}.JOB.log                               \
    compute-cmvn-stats --config=${config}                                          \
                       --spk2utt="ark:${data_dir}/spk2utt"                               \
                       "scp:${data_dir}/feats.scp"                                       \
                       "ark,scp:${cmvn_dir}/cmvn.JOB.ark,${cmvn_dir}/cmvn.JOB.scp"

cat ${cmvn_dir}/cmvn.*.scp > ${data_dir}/cmvn.scp