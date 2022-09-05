#!/bin/python3
import sys

def main():
    if 'NONE' in sys.argv[1]:
        print("Please use: 'make test_cpu TEST=<test file>'")
        return
    in_file = open(sys.argv[1], 'rb')
    in_data = in_file.read()
    in_file.close()
    in_data_formatted = in_data[3::-1].hex()
    for i in range(4, len(in_data), 4):
        num = in_data[i+3:i-1:-1]
        in_data_formatted = in_data_formatted + ' ' + num.hex()
    for i in range(len(in_data), 32768, 4):
        in_data_formatted = in_data_formatted + ' 00000000'
    out_file = open('cpu.mem', 'w')
    out_file.write(in_data_formatted)
    out_file.close()

if __name__ == '__main__':
    main()
