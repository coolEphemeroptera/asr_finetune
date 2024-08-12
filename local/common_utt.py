# 将这个脚本保存为 script.py 并运行
def read_file_to_dict(filename):
    result = {}
    with open(filename, 'r') as file:
        for line in file:
            parts = line.strip().split()
            if parts:
                result[parts[0]] = line.strip()
    return result

def find_common_lines(file1, file2):
    data1 = read_file_to_dict(file1)
    data2 = read_file_to_dict(file2)
    
    common_keys = set(data1.keys()) & set(data2.keys())
    for key in common_keys:
        print(key)

if __name__ == "__main__":
    import sys
    file1 = sys.argv[1]
    file2 = sys.argv[2]


    find_common_lines(file1, file2)
