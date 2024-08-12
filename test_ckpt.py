
import subprocess
import numpy as np 
from funasr import AutoModel
from compute_mer import compute_mer_text
import os 
SR = 16000

def audio_f2i(data, width=16):
    """将浮点数音频数据转换为整数音频数据。"""
    data = np.array(data)
    return np.int16(data * (2 ** (width - 1)))

def audio_i2f(data, width=16):
    """将整数音频数据转换为浮点数音频数据。"""
    data = np.array(data)
    return np.float32(data / (2 ** (width - 1)))

def read_audio_data(audio_file):
    """读取音频文件数据并转换为PCM格式。"""
    ffmpeg_cmd = [
        'ffmpeg',
        '-i', audio_file,
        '-f', 's16le',
        '-acodec', 'pcm_s16le',
        '-ar', '16k',
        '-ac', '1',
        'pipe:']
    with subprocess.Popen(ffmpeg_cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=False) as proc:
        stdout_data, stderr_data = proc.communicate()
    pcm_data = np.frombuffer(stdout_data, dtype=np.int16)
    pcm_data = audio_i2f(pcm_data)
    return pcm_data

if __name__ == "__main__":

    model_dir = "/opt/wangwei/asr_funasr/funasr_models/iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch"
    # model_ckpt = '/opt/wangwei/asr_funasr/funasr_models/iic/speech_paraformer-large-vad-punc_asr_nat-zh-cn-16k-common-vocab8404-pytorch/model.pt'
    model_ckpt = '/opt/wangwei/asr_finetune/egs3/outputs/model.pt.ep3'
    model = AutoModel(model=model_dir,
                      init_param=model_ckpt,
                      batch_size=20,
                    #   device = "cpu"
                      )
    
    mers = []
    dir = "/opt/wangwei/audio/dataset1"
    audio_format = 'mp3'
    for utt in sorted(os.listdir(dir)):
        if audio_format not in utt: continue 
        utt = utt.split(".")[0]
        audio_file = f"{dir}/{utt}.{audio_format}"
        trans_file = f"{dir}/{utt}.txt"

        with open(trans_file,'rt') as f:
            audio_trans = f.read()
        audio_data = read_audio_data(audio_file)
        audio_length = len(audio_data)
        window_size = int(30*SR)

        windows = []
        for i in range(0, audio_length, window_size):
            s, e = i, min(i + window_size, audio_length)
            window = audio_data[s:e]
            windows.append(window)
        results = model.generate(windows)


        asr_text = ''
        for result in results:
            asr_text += result['text']
        mer = compute_mer_text(audio_trans, asr_text, show=False)
        mers.append(mer)
        print(utt)
        print(mer)
    print(np.mean(mers))

