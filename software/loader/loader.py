#!/bin/python3
import serial
import sys

EXPECTED_SIGNATURE = b'37839363'
END_ADDRESS = 0x8000
BLOCK_SIZE = 0x200
SERIAL = '/dev/ttyACM1'

def show_header():
  print("\nPROJECT-RISK loader v1.0")

def open_serial():
  print(f"Connecting to serial port {SERIAL}")
  return serial.Serial(SERIAL)

def read_address(ser, addr):
  ser.write(bytes(f"0{addr:04x}", encoding='ASCII'))
  return ser.read(2)

def read_bytes(ser, addr, length):
  ser.write(bytes(f"2{length:04x}{addr:04x}", encoding='ASCII'))
  return ser.read(length * 2)

def write_address(ser, addr, data):
  ser.write(bytes(f"1{addr:04x}{data:02x}", encoding='ASCII'))
  return (ser.read(1) == b'g')

def get_signature(ser):
  signature  = read_address(ser, 0x7E00)
  signature += read_address(ser, 0x7E04)
  signature += read_address(ser, 0x7E08)
  signature += read_address(ser, 0x7E0C)
  return signature

def print_progress_bar (iteration, total, prefix = '', suffix = 'Complete', decimals = 1, length = 60, fill = '█', print_end = "\r"):
  percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
  filled_length = int(length * iteration // total)
  bar = fill * filled_length + '-' * (length - filled_length)
  print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = print_end)
  if iteration == total:
    print()

def check_signature(ser):
  sig = get_signature(ser)
  print(f"Checking signature: 0x{str(sig)[2:-1]} ", end='')
  if sig != EXPECTED_SIGNATURE:
    print("(\033[34mUNKNOWN\033[0m)")
    sys.exit(1)
  print("(\033[32mOK\033[0m)\n")

def get_memory(ser):
  print(f"Reading memory contents ({END_ADDRESS / 1024}Kb):")
  res = bytes()
  print_progress_bar(0, END_ADDRESS, prefix = 'Reading:')
  for i in range(0, END_ADDRESS, BLOCK_SIZE):
    res += read_bytes(ser, i, BLOCK_SIZE)
    print_progress_bar(i + BLOCK_SIZE, END_ADDRESS, prefix = 'Reading:')
  print()
  return res

def check_memmap_byte(mem, i, j, k):
  byte0 = mem[i * 1024 + j * 16 + k * 2]
  byte1 = mem[i * 1024 + j * 16 + k * 2 + 1]
  return (byte0.bit_count() % 2 != 0) ^ (byte1.bit_count() % 2 != 0)

def show_memory_map(mem):
  print('Memory map:\n' + '+' + '-' * 66 + '+')
  for i in range(len(mem) // 1024):
    print(end='| ')
    for j in range(64):
      char = 0x2800
      char += check_memmap_byte(mem, i, j, 0) << 0
      char += check_memmap_byte(mem, i, j, 1) << 1
      char += check_memmap_byte(mem, i, j, 2) << 2
      char += check_memmap_byte(mem, i, j, 3) << 6
      char += check_memmap_byte(mem, i, j, 4) << 3
      char += check_memmap_byte(mem, i, j, 5) << 4
      char += check_memmap_byte(mem, i, j, 6) << 5
      char += check_memmap_byte(mem, i, j, 7) << 7
      print(chr(char), end='')
    print(' |')
  print('+' + '-' * 66 + '+')
  pass

show_header()
ser = open_serial()
check_signature(ser)
memory = bytes.fromhex(str(get_memory(ser))[2:-1])
show_memory_map(memory)
ser.close()
