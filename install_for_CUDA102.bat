@REM ENUNU Portable Train Kit �p�̊��\�z�o�b�`�t�@�C��
@REM CUDA 10.2 ������

pip install --upgrade pip
pip install wheel
pip install numpy cython
pip install hydra-core<1.1
pip install utaupy tqdm pydub pyyaml
pip install torch==1.8.1+cu102 torchvision==0.9.1+cu102 torchaudio===0.8.1 -f "https://download.pytorch.org/whl/torch_stable.html"

git clone "https://github.com/r9y9/nnsvs"
pip install ./nnsvs
