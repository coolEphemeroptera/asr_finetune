#!/bin/bash

# 设置数据集路径
dataset='/opt/wangwei/audio/audio/train'

# 设置数据目录和输出目录
data_dir='egs2'
output_dir="$data_dir/outputs"
log_file="${output_dir}/log.txt"

# 设置训练脚本路径
script='/opt/wangwei/FunASR/funasr/bin/train.py'

# 设置 GPU 数量
gpu_num=1

# 设置模型路径
model_name_or_model_dir='/opt/wangwei/asr_funasr/funasr_models/iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch'

# 设置 CUDA 可见设备
export CUDA_VISIBLE_DEVICES="0"

# 创建数据目录和输出目录
mkdir -p $data_dir $output_dir

# 设置训练和验证数据文件路径
train_data="${data_dir}/train.jsonl"
val_data="${data_dir}/val.jsonl"

# 设置验证集大小
val_n=100

# 设置并行作业数量
nj=10

# 生成 wav 和 txt 文件列表的 SCP 文件
bash local/search.sh $dataset wav scp | sort | uniq > $data_dir/wav_raw.scp
bash local/search.sh $dataset txt scp | sort | uniq > $data_dir/txt_raw.scp

# 清理文本数据
python3 local/clean_text.py $data_dir/txt_raw.scp $nj $data_dir/text_raw.scp

# 生成公共 utt 文件
python3 local/common_utt.py $data_dir/wav_raw.scp $data_dir/text_raw.scp > $data_dir/common.utt

# 过滤和排序 SCP 文件
perl local/filter_scp.pl $data_dir/common.utt $data_dir/wav_raw.scp | sort > $data_dir/wav.scp
perl local/filter_scp.pl $data_dir/common.utt $data_dir/text_raw.scp | sort > $data_dir/text.scp

# 从 text.scp 文件中随机抽取验证集样本，并生成验证集 SCP 文件
cat $data_dir/text.scp | shuf -n $val_n | sort > $data_dir/text.val.scp
perl local/filter_scp.pl $data_dir/text.val.scp $data_dir/wav.scp | sort > $data_dir/wav.val.scp

# 从训练集 SCP 文件中排除验证集样本，生成训练集 SCP 文件
perl local/filter_scp.pl --exclude $data_dir/text.val.scp $data_dir/wav.scp | sort > $data_dir/wav.train.scp
perl local/filter_scp.pl --exclude $data_dir/text.val.scp $data_dir/text.scp | sort > $data_dir/text.train.scp

# 将 SCP 文件转换为 JSONL 格式
scp2jsonl \
++scp_file_list="[\"$data_dir/wav.train.scp\", \"$data_dir/text.train.scp\"]" \
++data_type_list='["source", "target"]' \
++jsonl_file_out="${train_data}"

scp2jsonl \
++scp_file_list="[\"$data_dir/wav.val.scp\", \"$data_dir/text.val.scp\"]" \
++data_type_list='["source", "target"]' \
++jsonl_file_out="${val_data}"

# 运行训练脚本
python3 $script \
++model="${model_name_or_model_dir}" \
++train_data_set_list="${train_data}" \
++valid_data_set_list="${val_data}" \
++dataset="AudioDataset" \
++dataset_conf.index_ds="IndexDSJsonl" \
++dataset_conf.data_split_num=1 \
++dataset_conf.batch_sampler="BatchSampler" \
++dataset_conf.batch_size=10000  \
++dataset_conf.sort_size=1024 \
++dataset_conf.batch_type="token" \
++dataset_conf.max_token_length=3000 \
++dataset_conf.num_workers=4 \
++train_conf.max_epoch=3 \
++train_conf.log_interval=10 \
++train_conf.resume=false \
++train_conf.validate_interval=10000 \
++train_conf.save_checkpoint_interval=10000 \
++train_conf.keep_nbest_models=20 \
++train_conf.avg_nbest_model=10 \
++optim_conf.lr=0.0001 \
++freeze_param="[]" \
++output_dir="${output_dir}"
