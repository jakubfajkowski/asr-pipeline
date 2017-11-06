#!/usr/bin/env bash

source $(which log.sh)
source $(which arguments.sh)

SCRIPT_FILE="$(basename ${0})"
SCRIPT_NAME="$(echo ${SCRIPT_FILE} | strip_extension.sh)"

register_optional_argument "--output_dir" "output_dir" "" "directory in which split files will be stored"
register_positional_argument "scp_file" "an scp file to split"
register_positional_argument "num" "number of files to split to"
parse_arguments $@

if [ "${output_dir}" == "" ]; then
    output_dir="$(echo ${scp_file} | strip_extension.sh)"
fi

lines=$(cat ${scp_file} | wc -l)
if ((lines == 0)); then
    log.sh -ent "File ${scp_file} is empty!"
    exit 1
fi

lines_per_file=$((lines / num))
if ((lines_per_file == 0)); then
    log.sh -wnt "${num} is too many! Spliting into ${lines} files."
    num=$(lines)
    lines_per_file=$((lines / num))
fi


prefix=$(basename ${scp_file} | strip_extension.sh)
mkdir -p ${output_dir}
split --number "l/${num}"       \
      --numeric-suffixes="1"     \
      --suffix-length="${#num}" \
      --additional-suffix=".scp" \
      --elide-empty-files        \
      "${scp_file}"              \
      "${output_dir}/${prefix}."
rename "s/${prefix}.0+/${prefix}./" ${output_dir}/*.scp