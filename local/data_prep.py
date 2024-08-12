import subprocess
import sys
import random
import os 

dataset = sys.argv[1]
val_rate = float(sys.argv[2])
outdir = sys.argv[3]

if not os.path.exists(outdir):os.makedirs(outdir)

with subprocess.Popen(f'bash local/search.sh {dataset} wav scp | sort > {outdir}/wav.scp ',shell=True) as p:
    p.wait()
with subprocess.Popen(f'bash local/search.sh {dataset} wav scp | sort > {outdir}/text.scp ',shell=True) as p:
    p.wait()

f1 = open(f'{outdir}/wav.scp','rt')
f2 = open(f'{outdir}/text.scp','rt')
wav_scp = f1.readlines()
text_scp = f2.readlines()
f1.close()
f2.close()

data_n = len(wav_scp)
val_n = int(val_rate*data_n)
val_idx = random.sample(list(range(data_n)),val_n)
f1 = open(f'{outdir}/wav_train.scp','wt')
f2 = open(f'{outdir}/text_train.scp','wt')
f3 = open(f'{outdir}/wav_val.scp','wt')
f4 = open(f'{outdir}/text_val.scp','wt')
for i in range(data_n):
    if i in val_idx:
        print(wav_scp[i],file=f3)