#!/bin/python3
'''
    File: selftest.py
    Author: EPSILON0-dev (lforenc@wp.pl)
    Description: This is a small selftest script for the emulator
    Date: 02.01.2022
'''

import subprocess
import json


TIMEOUT = 1 # s
OPERATIONS = [
    'simple',
    'add', 'and', 'or', 'sll', 'slt', 'sltu', 'sra', 'srl', 'sub', 'xor',
    'addi', 'andi', 'ori', 'slli', 'slti', 'sltiu', 'srai', 'srli', 'xori', 
    'auipc', 'lui',
    'jal', 'jalr',
    'beq', 'bge', 'bgeu', 'blt', 'bltu', 'bne',
    'lw', 'lhu', 'lh', 'lbu', 'lb',
    'sw', 'sh', 'sb',
    'dcache'
]


def test(tst):
    cmd = './bin/main -k 0x10000 -e -j ../tests/bin/' + tst + '.hex'
    try:
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return -1
    jsonOut = json.loads(output)
    return jsonOut["x3"]



def main():
    fail = 0
    for i in OPERATIONS:
        print('\x1b[32;1m-> \x1b[37;1m' + i.ljust(6, ' ') + '\x1b[32;1m ... \x1b[0m', end='')
        result = test(i)
        if result == 0x555:
            print('\x1b[32;1mOK\x1b[0m')
        elif result == -1:
            fail = 1
            print('\x1b[33;1mTIMEOUT\x1b[0m')
        else:
            fail = 1
            print('\x1b[31;1mFailed test: ' + str(result) + '\x1b[0m')
    if fail:
        print('\n\x1b[37;1mFailed...\n\x1b[0m')

if __name__ == '__main__':
    main()
