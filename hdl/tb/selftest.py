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
    return 'Killed by timeout'

def main():
    # Get the tests
    tests = run('ls -1 ../tests/bin')

    # Run all tests
    for test in tests:
        run(f'tb/test.py ../tests/bin/{test}')
        result = run('vvp obj/cpu_tb.obj')
        result_line = find_arr(result, '(00010000)')
        cycles_taken = result[-1].split(' ')[-1]
        if '1365' in result_line:
            print(f'\033[32;1mPassed test \033[97;1m{test.split(".")[0]} \033[20G\033[0m({cycles_taken})')
        else:
            print(f'\033[31;1mFailed test \033[97;1m{test.split(".")[0]} \033[20G\033[0m(Failed Test {result_line.split(" ")[-2]})')

if __name__ == '__main__':
    main()