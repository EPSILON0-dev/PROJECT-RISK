#!/bin/python3
'''
    File: showres.py
    Author: EPSILON0-dev (lforenc@wp.pl)
    Description: This is a script will (hopefully) help me visualise the behaviour of the CPU, and debug some stuff...
    Date: 02.01.2022
'''

# Imports
from math import ceil, floor
import subprocess
import sys
import json
import curses

# Constants
TIMEOUT = 1
REG_NAMES = [
    'zero', 'ra',   'sp',   'gp',
    'tp',   't0',   't1',   't2',
    's0',   's1',   'a0',   'a1',
    's2',   's3',   'a4',   'a5',
    'a6',   'a7',   's2',   's3',
    's4',   's5',   's6',   's7',
    's8',   's9',   's10',  's11',
    't3',   't4',   't5',   't6'
]

ALU_OPS = [
    'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 
    'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 
    'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 
    'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 'DEF', 
    'ADD', 'SLL', 'SLT', 'SLU', 'XOR', 'SRL', ' OR', 'AND',
    'SUB', 'SLL', 'SLT', 'SLU', 'XOR', 'SRA', ' OR', 'AND',
    'ADD', 'SLL', 'SLT', 'SLU', 'XOR', 'SRL', ' OR', 'AND',
    'ADD', 'SLL', 'SLT', 'SLU', 'XOR', 'SRA', ' OR', 'AND'
]

# Global vars
reg_updates = []


# Test function
def test():
    cmd = './bin/main -l -j -k 0x10000 ../tests/bin/' + sys.argv[1] + '.hex'
    try:
        output = subprocess.check_output(cmd, shell=True, stderr=subprocess.STDOUT, timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        return -1
    return output



# Generate reg update log based on json_cycles
def gen_reg_update_log(json_cycles):
    reg_updates = []
    
    # For every cycle if wb was enabled create log entry
    for cycle in range(len(json_cycles)):
        json_cycle = json.loads(json_cycles[cycle])
        if json_cycle['wb_c9'] == 1 and json_cycle['wb_c8'] != 0:
            if json_cycle['i_fetch'] == 1 and json_cycle['d_fetch'] == 1 and json_cycle['x' + str(json_cycle['wb_c8'])] != json_cycle['wb_wb']:
                reg_updates.append([cycle+1, str(json_cycle['wb_c8']), str(json_cycle['x' + str(json_cycle['wb_c8'])]), str(json_cycle['wb_wb'])])

    return reg_updates



# Generate dump
def gen_dump():
    dump_file = open('../tests/dump/' + sys.argv[1] + '.dump', 'r')
    dump_string = dump_file.read()
    dump_lines = dump_string.splitlines()
    ret = []
    for line in dump_lines:
        try:
            ret.append((int(line.split(':')[0], 16), line))
        except ValueError:
            ret.append((-1, line))
    return ret



# Init curses color pairs
def curses_init():
    curses.init_pair(1, curses.COLOR_BLUE, curses.COLOR_BLACK)
    curses.init_pair(2, curses.COLOR_GREEN, curses.COLOR_BLACK)
    curses.init_pair(3, curses.COLOR_MAGENTA, curses.COLOR_BLACK)
    curses.init_pair(4, curses.COLOR_RED, curses.COLOR_BLACK)
    curses.init_pair(5, curses.COLOR_YELLOW, curses.COLOR_BLACK)
    curses.init_pair(6, curses.COLOR_GREEN, curses.COLOR_BLACK)



# Print colorful hex value
def print_hex(win, val):
    reg_str = f'{val:#010x} '[2:]
    reg_col = 1
    if val != 0:
        reg_col = 2
        if val > 0x7FFFFFFF:
            reg_col = 3
    win.addstr(reg_str, curses.color_pair(reg_col))



# Render cycle clounter
def render_cycle(cyc_win, json_cycles, cur_cycle):
    
    # Get the status value
    cycle = json.loads(json_cycles[cur_cycle])

    # Print the status
    cyc_win.clear()
    cyc_win.addstr('CYCLE: ' + str(cur_cycle), curses.A_BOLD)
    ok = 1 
    if cycle['hz_dat'] == 1:
        cyc_win.addstr(', ')
        cyc_win.addstr('Data', curses.color_pair(4))
        ok = 0
    if cycle['hz_br'] == 1:
        cyc_win.addstr(', ')
        cyc_win.addstr('Branch', curses.color_pair(4))
        ok = 0
    if cycle['i_fetch'] != 1:
        cyc_win.addstr(', ')
        cyc_win.addstr('ICACHE', curses.color_pair(5))
        ok = 0
    if cycle['d_fetch'] != 1:
        cyc_win.addstr(', ')
        cyc_win.addstr('DCACHE', curses.color_pair(5))
        ok = 0
    if ok:
        cyc_win.addstr(', ')
        cyc_win.addstr('OK', curses.color_pair(6))
    cyc_win.refresh()


# Render cycle clounter
def get_status(json_cycles, cur_cycle):
    
    # Get the status value
    cycle = json.loads(json_cycles[cur_cycle])

    if cycle['hz_dat'] == 1:
        return 0
    if cycle['hz_br'] == 1:
        return 0
    if cycle['i_fetch'] != 1:
        return 0
    if cycle['d_fetch'] != 1:
        return 0
    return 1
    


# Render registers as 8 rows of 4 32-bit regs
def render_registers(reg_win, json_cycles, cur_cycle):
    
    # Window stuff
    reg_win.clear()

    # Get the registers

    cycle = json.loads(json_cycles[cur_cycle])
    for reg in range(32):
        print_hex(reg_win, cycle['x' + str(reg)])
    
    # Render PC
    reg_win.addstr('─'*36)
    reg_win.addstr('PC: ', curses.A_BOLD)
    reg_win.addstr(f'{cycle["id_pc"]:#010x}'[2:], curses.color_pair(1))

    reg_win.addstr('   CE: ')
    if (cycle["ce_if"]):
        reg_win.addstr('IF ', curses.A_BOLD)
    else:
        reg_win.addstr('IF ')
    if (cycle["ce_id"]):
        reg_win.addstr('ID ', curses.A_BOLD)
    else:
        reg_win.addstr('ID ')
    if (cycle["ce_ex"]):
        reg_win.addstr('EX ', curses.A_BOLD)
    else:
        reg_win.addstr('EX ')
    if (cycle["ce_mem"]):
        reg_win.addstr('MA ', curses.A_BOLD)
    else:
        reg_win.addstr('MA ')
    if (cycle["ce_wb"]):
        reg_win.addstr('WB ', curses.A_BOLD)
    else:
        reg_win.addstr('WB ')

    # Window stuff
    reg_win.refresh()



# Render log
def render_reg_update_log(reg_log_win, reg_updates, cur_cycle):
    
    # Window stuff
    reg_log_win.clear()

    # Create a list of displayed log entries
    displayed_log = []
    for update in reg_updates:
        if int(update[0]) > cur_cycle:
            break
        displayed_log.append(update)

    # Clip the log entries
    displayed_log = displayed_log[-(curses.LINES - 20):]

    # Display the log entries
    for log in displayed_log:

        # Convert to ints
        log = [0, int(log[1]), int(log[2]), int(log[3])]

        # Print register name
        reg = REG_NAMES[log[1]]
        if len(reg) == 2:
            reg_log_win.addstr(f'  <{reg}>: ', curses.A_BOLD)
        else:
            reg_log_win.addstr(f' <{reg}>: ', curses.A_BOLD)

        # Print prev value
        print_hex(reg_log_win, log[2])

        # Print arrow
        reg_log_win.addstr('-> ', curses.A_BOLD)

        # Print new value
        print_hex(reg_log_win, log[3])

        # Print line feed
        reg_log_win.addstr('\n')

    # Window stuff
    reg_log_win.refresh()



# Render pipeline register status
def render_status(stat_win, json_cycles, cur_cycle):
    
    # Window stuff
    stat_win.clear()

    # Get current cycle
    cycle = json.loads(json_cycles[cur_cycle])

    # Print ID registers
    stat_win.addstr('ID_IR  -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['id_ir'])
    stat_win.addstr(' |  ID_PC  -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['id_pc'])
    stat_win.addstr(' |  ID_RET -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['id_ret'])

    # Print EX registers
    stat_win.addstr('EX_RD1 -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['ex_rd1'])
    stat_win.addstr(' |  EX_RD2 -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['ex_rd2'])
    stat_win.addstr(' |  EX_IMM -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['ex_imm'])
    stat_win.addstr('EX_PC  -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['ex_pc'])
    stat_win.addstr(' |  EX_RET -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['ex_ret'])

    # Print MA registers
    stat_win.addstr(' |  MA_RD2 -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['mem_rd2'])
    stat_win.addstr('MA_ALU -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['mem_alu'])
    stat_win.addstr(' |  MA_RET -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['mem_ret'])
    
    # Print WB registers
    stat_win.addstr(' |  WB_WB  -> ', curses.A_BOLD)
    print_hex(stat_win, cycle['wb_wb'])
    stat_win.addstr('─'*65, curses.A_BOLD)

    # Print EX control flow
    stat_win.addstr('EX_BR -> ', curses.A_BOLD)
    stat_win.addstr(['---','TKN'][cycle["ex_cb"]])
    stat_win.addstr('  |  EX_AI -> ', curses.A_BOLD)
    stat_win.addstr(['RD1', ' PC'][cycle['ex_c3']])
    stat_win.addstr('  |  EX_AI -> ', curses.A_BOLD)
    stat_win.addstr(['RD2', 'IMM'][cycle['ex_c2']])
    stat_win.addstr('  |  EX_AL -> ', curses.A_BOLD)
    stat_win.addstr(ALU_OPS[cycle['ex_c4']])
    stat_win.addstr('\nEX_RW -> ', curses.A_BOLD)
    stat_win.addstr(['NOP', ' WR', ' RD', 'WTF'][((cycle['ex_c6']>0)<<1)+(cycle['ex_c5']>0)])
    stat_win.addstr('  |  EX_WB -> ', curses.A_BOLD)
    stat_win.addstr(['NOP', 'NOP', 'NOP', 'NOP', 'ALU', ' RD', 'RET', 'WTF'][cycle['ex_c7']+(cycle['ex_c9']<<2)])
    

    # Print MA control flow
    stat_win.addstr('  |  MA_RW -> ', curses.A_BOLD)
    stat_win.addstr(['NOP', ' WR', ' RD', 'WTF'][((cycle['mem_c6']>0)<<1)+(cycle['mem_c5']>0)])
    stat_win.addstr('  |  MA_WB -> ', curses.A_BOLD)
    stat_win.addstr(['NOP', 'NOP', 'NOP', 'NOP', 'ALU', ' RD', 'RET', 'WTF'][cycle['mem_c7']+(cycle['mem_c9']<<2)])
    stat_win.addstr('\n'+'─'*65, curses.A_BOLD)


    # Print memory messages
    stat_win.addstr('ICACHE -> ', curses.A_BOLD)
    stat_win.addstr(cycle['mi'])
    stat_win.addstr('\nDCACHE -> ', curses.A_BOLD)
    stat_win.addstr(cycle['md'])
    stat_win.addstr('\nDDR    -> ', curses.A_BOLD)
    stat_win.addstr(cycle['mr'])
    stat_win.addstr('\nFSB    -> ', curses.A_BOLD)
    stat_win.addstr(cycle['mf'])


    # Window stuff
    stat_win.refresh()



# Render pipeline register status
def render_raw(raw_win, json_cycles, cur_cycle):
    # Window stuff
    raw_win.clear()

    # Get current cycle
    cycle = json.loads(json_cycles[cur_cycle])

    # Print ID registers
    for i in range(1, 10):
        raw_win.addstr(' c' + str(i) + ' -> ', curses.A_BOLD)
        raw_win.addstr(str(cycle['ex_c'+str(i)])+'\n')

    # Window stuff
    raw_win.refresh()



def render_dump(dump_win, lines, dump, json_cycles, cur_cycle):
    
    # Window stuff
    dump_win.clear()

    top = int((lines-1) / 2)
    bot = int((lines-1) / 2)

    # Window stuff
    line = 0
    for i in range(len(dump)):
        if dump[i][0] == json.loads(json_cycles[cur_cycle-1])['if_pc']:
            line = i
            break

    if line - top < 0:
        bot += top - line
        top = line

    for i in range(top):
        dump_win.addstr('   ' + dump[line-top+i][1] + '\n')

    dump_win.addstr('-> ', curses.A_BOLD)
    dump_win.addstr(dump[line][1] + '\n')

    for i in range(bot-2):
        try:
            dump_win.addstr('   ' + dump[line+1+i][1] + '\n')
        except IndexError:
            pass

    # Window stuff
    dump_win.refresh()



# Main function
def main(stdscr):
    # Do the test
    json_cycles = str(test()).split('\\n')[:-1]
    json_cycles[0] = json_cycles[0].split('\'')[1]
    reg_updates = gen_reg_update_log(json_cycles)
    dump = gen_dump()
    cur_cycle = 0

    # Initialize curses
    curses_init()

    # Create windows
    reg_win = curses.newwin(10, 36, 3, 2)
    reg_log_win = curses.newwin(curses.LINES - 19, 36, 16, 2)
    cyc_win = curses.newwin(1, 36, curses.LINES - 2, 2)
    stat_win = curses.newwin(14, 65, 3, 40)
    raw_win = curses.newwin(14, curses.COLS-107, 3, 106)
    dump_win = curses.newwin(curses.LINES - 21, curses.COLS - 41, 20, 40)
    
    # Clear, print the background and refresh the main screen
    stdscr.clear()
    stdscr.addstr('╔'  + '═'*37 + '╦'  + '═'*66 + '╦' + '═'*(curses.COLS-107) + '╗')
    stdscr.addstr('║'  + ' '*13 + ' REGISTERS ' + ' '*13 + '║' + ' '*29 + ' STATUS ' + ' '*29 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('╟'  + '─'*37 + '╫'  + '─'*66 + '╫' + '─'*(curses.COLS-107) + '╢')
    stdscr.addstr(('║' + ' '*37 + '║'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')*4)
    stdscr.addstr('║'  + ' '*37 + '╟─' + ' '*65 + '╢' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr(('║' + ' '*37 + '║'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')*2)
    stdscr.addstr('║'  + ' '*37 + '╟─' + ' '*65 + '╢' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('╟─' + ' '*36 + '╢'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('║'  + ' '*37 + '║'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('╠'  + '═'*37 + '╣'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('║'  + ' '*8 + ' REGISTER CHANGE LOG ' + ' '*8 + '║' + ' '*66 + '║' + ' '*(curses.COLS-107) + '║') #  + '║')
    stdscr.addstr('╟'  + '─'*37 + '╢'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('║'  + ' '*37 + '║'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('║'  + ' '*37 + '╠'  + '═'*66 + '╩' + '═'*(curses.COLS-107) + '╣')
    stdscr.addstr('║'  + ' '*37 + '║'  + ' '*ceil((curses.COLS-55)/2) + ' ASSEMBLY DUMP ' + ' '*floor((curses.COLS-55)/2)+ '║')
    stdscr.addstr('║'  + ' '*37 + '╟'  + '─'*66 + '─' + '─'*(curses.COLS-107) + '╢')
    stdscr.addstr(('║' + ' '*37 + '║'  + ' '*66 + ' ' + ' '*(curses.COLS-107) + '║')*(curses.LINES-23))
    stdscr.addstr('╠'  + '═'*37 + '╣'  + ' '*66 + ' ' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('║'  + ' '*37 + '║'  + ' '*66 + '║' + ' '*(curses.COLS-107) + '║')
    stdscr.addstr('╚'  + '═'*37 + '╩'  + '═'*66 + '═' + '═'*(curses.COLS-107))
    stdscr.refresh()
    
    while 1:
        # Render result
        render_registers(reg_win, json_cycles, cur_cycle)
        render_cycle(cyc_win, json_cycles, cur_cycle)
        render_reg_update_log(reg_log_win, reg_updates, cur_cycle)
        render_status(stat_win, json_cycles, cur_cycle)
        render_raw(raw_win, json_cycles, cur_cycle)
        render_dump(dump_win, curses.LINES - 21, dump, json_cycles, cur_cycle)

        # Get the keyboard input
        key = stdscr.getch()
        if key == ord('w'):
            if cur_cycle < len(json_cycles) - 1:
                cur_cycle += 1
        elif key == ord('s'):
            if cur_cycle > 0:
                cur_cycle -= 1

        elif key == ord('e'):
            if cur_cycle < len(json_cycles) - 1:
                cur_cycle += 1
                while not get_status(json_cycles, cur_cycle):
                    if cur_cycle >= len(json_cycles) - 1:
                        break
                    cur_cycle += 1
        elif key == ord('d'):
            if cur_cycle > 0:
                cur_cycle -= 1
                while not get_status(json_cycles, cur_cycle):
                    if cur_cycle <= 0:
                        break
                    cur_cycle -= 1

        elif key == ord('g'):
            cur_cycle = 0
        elif key == ord('G'):
            cur_cycle = len(json_cycles) - 2

        elif key == ord('q'):
            break



# Main function call
if __name__ == '__main__':
    curses.wrapper(main)
