#!/bin/bash

##########
# customized for ENUNU-Training-Kit on Windows
##########
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

function xrun () {
    set -x
    $@
    set +x
}

# use embed python executional file
alias python="./../python-3.8.10-embed-amd64/python"

script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

NNSVS_ROOT=../nnsvs
NNSVS_COMMON_ROOT=$NNSVS_ROOT/egs/_common/spsvs
NO2_ROOT=$NNSVS_ROOT/egs/_common/no2
. "$NNSVS_ROOT/utils/yaml_parser.sh" || exit 1;

eval $(parse_yaml "./config.yaml" "")

train_set=train_no_dev
dev_set=dev
eval_set=eval
datasets=($train_set $dev_set $eval_set)
testsets=($dev_set $eval_set)

dumpdir=dump
dump_org_dir=$dumpdir/$spk/org
dump_norm_dir=$dumpdir/$spk/norm

stage=0
stop_stage=0

. $NNSVS_ROOT/utils/parse_options.sh || exit 1;

# exp name
if [ -z ${tag:=} ]; then
    expname=${spk}
else
    expname=${spk}_${tag}
fi
expdir=exp/$expname


# assert singing-database exits
if [ ${stage} -le -1 ] && [ ${stop_stage} -ge -1 ]; then
    if [ ! -e $db_root ]; then
	cat<<EOF
singing-database files were not found
EOF
    fi
fi


# Prepare files in singing-database for training
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "stage 0: Data preparation"
    rm -rf data dump
    bash data_prep.sh ./config.yaml
fi


# Analyze .wav and .lab files
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "stage 1: Feature generation"
    . $NNSVS_COMMON_ROOT/feature_generation.sh
fi


# Train time-lag model
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "stage 2: Training time-lag model"
    . $NNSVS_COMMON_ROOT/train_timelag.sh
fi


# Train duration model
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "stage 3: Training duration model"
    . $NNSVS_COMMON_ROOT/train_duration.sh
fi


# Train acoustic model
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Training acoustic model"
    . $NNSVS_COMMON_ROOT/train_acoustic.sh
fi


# Generate models from timelag/duration/acoustic models
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Generate features"
    . $NNSVS_COMMON_ROOT/generate.sh
fi


# Synthesis wav files
if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    echo "stage 6: Synthesis waveforms"
    . $NNSVS_COMMON_ROOT/synthesis.sh
fi


# Copy the models to release directory
if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    echo "stage 7: Copy models to release directory"
    python prepare_model_for_release_enunu.py
