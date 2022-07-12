set -e
set -u
set -o pipefail

function xrun () {
    set -x
    $@
    set +x
}

CONFIG_PATH="config.yaml"

script_dir=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
NNSVS_ROOT="/content/nnsvs"
NNSVS_COMMON_ROOT="/content/nnsvs/recipes/_common/spsvs"
. "$NNSVS_ROOT/utils/yaml_parser.sh" || exit 1;

eval $(parse_yaml $CONFIG_PATH "")

train_set="train_no_dev"
dev_set="dev"
eval_set="eval"
datasets=($train_set $dev_set $eval_set)
testsets=($dev_set $eval_set)

dumpdir=dump
dump_org_dir="$dumpdir/$spk/org"
dump_norm_dir="$dumpdir/$spk/norm"

stage=0
stop_stage=-1

. $NNSVS_ROOT/utils/parse_options.sh || exit 1;


if [ -z ${tag:=} ]; then
    expname="${spk}"
else
    expname="${spk}_${tag}"
fi
expdir="exp/$expname"


# Prepare files in singing-database for training
if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    echo "stage 0: Data preparation"
    rm -rf $out_dir
    rm -f preprocess_data.py.log
    python preprocess_data.py $CONFIG_PATH || exit 1;
fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "stage 1: Feature generation#"
    rm -rf $dumpdir
    . $NNSVS_COMMON_ROOT/feature_generation.sh || exit 1;
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "stage 2: Time-lag model training"
    . $NNSVS_COMMON_ROOT/train_timelag.sh || exit 1;
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "stage 3: Duration model training"
    . $NNSVS_COMMON_ROOT/train_duration.sh || exit 1;
fi

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    echo "stage 4: Training acoustic model"
    . $NNSVS_COMMON_ROOT/train_acoustic.sh || exit 1;
fi

if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "stage 5: Feature generation"
    . $NNSVS_COMMON_ROOT/generate.sh || exit 1;
fi

# if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
#     echo "stage 6: Waveform synthesis"
#     . $NNSVS_COMMON_ROOT/synthesis.sh
# fi

if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    echo "#  stage 7: Release preparation          #"
    python prepare_release.py $CONFIG_PATH || exit 1;
fi
