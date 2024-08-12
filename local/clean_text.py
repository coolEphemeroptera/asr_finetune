from concurrent.futures import ThreadPoolExecutor
import sys

def text_clean(text:str):
    # 清洗文本，去除标点符号
    return text.replace("，","").replace("？","").replace("。","").replace("！","").\
                            replace("《","").replace("》","").replace("、","").replace("：","").\
                            replace("“","").replace("”","").replace(",","").replace("、","").replace("?","").strip()
def rm_space(text:str):
    return "".join(text.split())

def process(line):
    # 处理单行数据，读取文件内容并清洗
    utt, path = line.strip().split()
    with open(path, 'rt') as f:
        content = text_clean(f.read())
        content = rm_space(content)
    return f'{utt} {content}'

if __name__ == "__main__":
    # 主函数，读取命令行参数和文件，使用线程池处理数据
    txt_file = sys.argv[1]
    nj = int(sys.argv[2])
    text_file = sys.argv[3]

    txt_scp = []
    with open(txt_file, 'rt') as f:
        txt_scp = f.readlines()

    # 使用 ThreadPoolExecutor 创建线程池
    with ThreadPoolExecutor(max_workers=nj) as executor:
        results = list(executor.map(process, txt_scp))

    # 输出处理结果
    nlines = 0
    ntokens = 0
    with open(text_file, 'wt') as f:
        for result in results:
            if len(result.split())<2:continue
            utt, text = result.split()
            nlines += 1
            ntokens += len(text)
            print(result,file=f)
    print('n lines:',nlines)
    print('n tokens:',ntokens)

