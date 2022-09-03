#!/bin/python3
import os
import subprocess

tests_simple = ['simple']
tests_imm    = ['addi', 'andi', 'ori', 'xori', 'slti', 'sltiu', 'slli', 'srai', 'srli']
tests_normal = ['add', 'sub', 'and', 'or', 'xor', 'slt', 'sltu', 'sll', 'sra', 'srl']
tests_branch = ['beq', 'bne', 'blt', 'bltu', 'bge', 'bgeu']
tests_load   = ['lb', 'lh', 'lw', 'lbu', 'lhu']
tests_store  = ['sb', 'sh', 'sw']
tests_misc   = ['jal', 'jalr', 'auipc', 'lui']
tests_cext   = ['rvc']
tests_mext   = ['mul', 'mulh', 'mulhu', 'mulhsu', 'div', 'divu', 'rem', 'remu']

# Simple subprocess wrapper
def run(cmd):
    output = subprocess.check_output(cmd, shell=True)
    return output.decode('utf-8').split('\n')[:-1]

# Find a string in array of strings
def find_line(arr, pattern):
    for line in arr:
        if line.find(pattern) >= 0:
            return line
    return 'Killed by timeout'

# Run given test
def run_test(test_name):
    run(f'tb/test.py ../tests/bin/{test_name}.hex')
    result = run('vvp obj/cpu_tb.obj')
    result_line = find_line(result, '(00010000)')
    cycles_taken = result[-1].split(' ')[-1]
    if '1365' in result_line:
        print(f'\033[32;1mPassed test \033[97;1m{test_name} \033[20G\033[0m({cycles_taken})')
        return cycles_taken
    else:
        print(f'\033[31;1mFailed test \033[97;1m{test_name} \033[20G\033[0m(Failed Test {result_line.split(" ")[-2]})')
        return -1

# Run given tests array
def run_test_arr(tests_name, tests_arr):
    print(f'\n\033[97;1mRunning {tests_name} tests:\033[0m')
    total_cycles = 0
    error = 0
    for test in tests_arr:
        cycles = run_test(test)
        if cycles == -1:
            error = 1
        total_cycles += int(cycles)
    return (total_cycles, error)


def main():
    total_cycles = 0

    # Run base isa tests
    (cycles, error) = run_test_arr('simple', tests_simple)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('register/immediate', tests_imm)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('register/register', tests_normal)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('branch', tests_branch)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('load', tests_load)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('store', tests_store)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    (cycles, error) = run_test_arr('miscellaneous', tests_misc)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles

    # Run M extenion tests
    (cycles, error) = run_test_arr('M extension', tests_mext)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles

    # Run C extension test
    (cycles, error) = run_test_arr('C extension', tests_cext)
    if not error: print(f'Taken \033[97;1m{cycles}\033[0m cycles'); total_cycles += cycles
    # Print total cycles taken
    print(f'\n\033[97;1mTotal cycles taken:\033[0m {total_cycles}')

if __name__ == '__main__':
    main()
