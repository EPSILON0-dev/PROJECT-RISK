#!/bin/python3
"""
  Script for converting the binary data to BRAM init
"""
def main():
  in_file = open("bin/out.bin", "rb")
  in_data = in_file.read()
  in_file.close()

  out_string = ''
  for i in range(32):
    out_string += f'.INIT_{i:02X}(256\'h'
    for j in range(32):
      data = b'\0'
      try:
        data = in_data[i * 32 + 31 - j]
      except IndexError:
        data = 0
      out_string += f'{data:02X}'
    out_string += '),\n'

  out_file = open("bin/top.mem", "w")
  out_file.write(out_string)
  out_file.close()

if __name__ == "__main__":
  main()