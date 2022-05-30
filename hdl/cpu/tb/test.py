#!/bin/python3
import sys

def main():
    if sys.argv[1] == 'NONE':
        print("Please use: 'make test_cpu TEST=<test file>'")
        return
    in_file = open(sys.argv[1], 'rb')
    in_data = in_file.read()
    in_file.close()
    in_data_formated = ''
    for i in range(0, len(in_data), 4):
        in_data_formated = in_data_formated + in_data[i+3:i-1:-1].hex() + ' '
    out_file = open('obj/cpu.mem', 'w')
    out_file.write(in_data_formated)
    out_file.close()

if __name__ == '__main__':
    main()