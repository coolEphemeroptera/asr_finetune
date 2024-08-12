# dataset='/opt/wangwei/asr_finetune/audio'
dataset='/dev/dataset_tts'
data_dir='egs3'
output_dir="$data_dir/outputs"
log_file="${output_dir}/log.txt"
script='/opt/wangwei/FunASR/funasr/bin/train.py'
gpu_num=1
# model_name_or_model_dir='/opt/wangwei/asr_funasr/funasr_models/iic/speech_seaco_paraformer_large_asr_nat-zh-cn-16k-common-vocab8404-pytorch'
model_name_or_model_dir='/opt/wangwei/asr_funasr/funasr_models/iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch'
export CUDA_VISIBLE_DEVICES="0"

# rm -rf $data_dir 
mkdir -p $data_dir $output_dir
train_data="${data_dir}/train.jsonl"
val_data="${data_dir}/val.jsonl"

val_n=1000
nj=10
bash local/search.sh $dataset wav scp | sort | uniq > $data_dir/wav_raw.scp
bash local/search.sh $dataset txt scp | sort | uniq > $data_dir/txt_raw.scp
python3 local/clean_text.py $data_dir/txt_raw.scp $nj $data_dir/text_raw.scp
python3 local/common_utt.py $data_dir/wav_raw.scp $data_dir/text_raw.scp > $data_dir/common.utt

perl local/filter_scp.pl $data_dir/common.utt $data_dir/wav_raw.scp | sort > $data_dir/wav.scp
perl local/filter_scp.pl $data_dir/common.utt $data_dir/text_raw.scp | sort > $data_dir/text.scp

cat $data_dir/text.scp | shuf -n $val_n | sort > $data_dir/text.val.scp
perl local/filter_scp.pl $data_dir/text.val.scp $data_dir/wav.scp | sort > $data_dir/wav.val.scp
perl local/filter_scp.pl --exclude $data_dir/text.val.scp $data_dir/wav.scp | sort > $data_dir/wav.train.scp
perl local/filter_scp.pl --exclude $data_dir/text.val.scp $data_dir/text.scp | sort > $data_dir/text.train.scp

scp2jsonl \
++scp_file_list="[\"$data_dir/wav.train.scp\", \"$data_dir/text.train.scp\"]" \
++data_type_list='["source", "target"]' \
++jsonl_file_out="${train_data}"

scp2jsonl \
++scp_file_list="[\"$data_dir/wav.val.scp\", \"$data_dir/text.val.scp\"]" \
++data_type_list='["source", "target"]' \
++jsonl_file_out="${val_data}"


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
++train_conf.max_epoch=4 \
++train_conf.log_interval=10 \
++train_conf.resume=false \
++train_conf.validate_interval=10000 \
++train_conf.save_checkpoint_interval=10000 \
++train_conf.keep_nbest_models=20 \
++train_conf.avg_nbest_model=10 \
++optim_conf.lr=0.0001 \
++freeze_param="[encoder]" \
++output_dir="${output_dir}"