#!/bin/python3
import os
import subprocess

# Simple subprocess wrapper
def run(cmd):
    output = subprocess.check_output(cmd, shell=True)
    return output.decode('utf-8').split('\n')[:-1]

# Find a string in array of strings
def find_arr(arr, pattern):
    for line in arr:
        if line.find(pattern) >= 0:
            return line

def main():
    # Get the tests
    tests = run('ls -1 ../../tests/bin')

    # Run all tests
    for test in tests:
        run(f'tb/test.py ../../tests/bin/{test}')
        result = run('vvp obj/cpu_tb.obj')
        result_line = find_arr(result, '(00010000)')
        if '00000555' in result_line:
            print(f'Passed test {test}')
        else:
            print(f'Failed test {test}: {result_line}')

if __name__ == '__main__':
    main()