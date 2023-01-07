#!/bin/python3
"""
  Simple Loader for working with the bootloader.
"""
import serial
import sys

EXPECTED_SIGNATURE = b'37839363'
END_ADDRESS = 0x8000
BLOCK_SIZE = 0x200
SERIAL = '/dev/ttyACM1'
FILE = ''

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

def write_bytes(ser, addr, data, length):
  ser.write(bytes(f"3{length:04x}", encoding='ASCII'))
  for i in length:
    ser.write(bytes(f"{data[i]:02x}"))
    if (ser.read(1) != b'k'):
      return False
  return True

def get_signature(ser):
  signature  = read_address(ser, 0x7E00)
  signature += read_address(ser, 0x7E04)
  signature += read_address(ser, 0x7E08)
  signature += read_address(ser, 0x7E0C)
  return signature

def print_progress_bar (iteration, total, prefix = '', suffix = 'Complete', decimals = 1, length = 60, fill = '#', print_end = "\r"):
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

def get_memory(ser, length):
  print(f"Reading memory contents ({length / 1024:.1f}Kb):")
  res = bytes()
  print_progress_bar(0, length, prefix = 'Reading:')
  for i in range(0, length, BLOCK_SIZE):
    res += read_bytes(ser, i, BLOCK_SIZE)
    print_progress_bar(min(i + BLOCK_SIZE, length), length, prefix = 'Reading:')
  return res

def set_memory(ser, memory: bytes):
  print(f"Writing memory contents ({len(memory) / 1024:.1f}Kb):")
  print_progress_bar(0, len(memory), prefix = 'Writing:')
  for i in range(len(memory)):
    write_address(ser, i, memory[i])
    print_progress_bar(i + 1, len(memory), prefix = 'Writing:')

def main():
  show_header()

  if len(sys.argv) != 4:
    print("Usage: ./loader.py [PORT] [read/write/verify] [FILE]")
    sys.exit(1)

  global SERIAL
  SERIAL = sys.argv[1]
  ser = open_serial()

  global FILE
  FILE = sys.argv[3]

  verify = False

  if sys.argv[2] == 'read':
    memory = bytes.fromhex(str(get_memory(ser, END_ADDRESS))[2:-1])
    f = open(FILE, 'wb')
    f.write(memory)
    f.close()

  elif sys.argv[2] == 'write':
    f = open(FILE, 'rb')
    memory = f.read()
    f.close()
    if len(memory) > END_ADDRESS:
      print('File to big to write')
      sys.exit(1)
    set_memory(ser, memory)
    verify = True

  if sys.argv[2] == 'verify' or verify:
    f = open(FILE, 'rb')
    memory_orig = f.read()
    f.close()
    ok = True
    memory = bytes.fromhex(str(get_memory(ser, len(memory_orig)))[2:-1])
    for i in range(len(memory_orig)):
      if memory_orig[i] != memory[i]:
        ok = False
        print(f"Verify failed on address {i:04X} {memory_orig[i]:02X} => {memory[i]:02X}")
    if ok:
      print("Verified OK.")

  ser.close()

if __name__ == '__main__':
  main()
