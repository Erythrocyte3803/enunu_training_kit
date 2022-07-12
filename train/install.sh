apt update
DEBIAN_FRONTEND=noninteractive apt-get install -qq p7zip-full p7zip-rar &> /dev/null
pip install --upgrade pip &> /dev/null

pip install wheel numpy cython==0.29.27 optuna "hydra-core >= 1.1.0, < 1.2.0" "hydra_colorlog >= 1.1.0" hydra-optuna-sweeper mlflow utaupy tqdm pydub pyyaml natsort github-clone torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu113 &> /dev/null
pip install -I git+https://github.com/r9y9/nnsvs.git &> /dev/null
