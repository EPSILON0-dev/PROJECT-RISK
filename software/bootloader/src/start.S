/**
 * Copyright 2023 Lukasz Forenc
 *
 * file: start.S
 *
 * This is a bootloader for the
 */
#include "hardware.h"

#define UART_CONFIGURATION  (2<<UART_LENGTH) | (1<<UART_RX_EN) | (1<<UART_TX_EN)
#define MEMORY_END          0x00008000
#define BLD_ADDRESS         0x00010000
#define F_CPU               6250000
#define BAUD_RATE           115200

.section .text

.globl _start
  # Enter the bootloader if ISP button held down
_start:                                 #
  li x2, IO_BLOCK                       # Load the IOBLOCK address to the x2 (iob)
  lw x3, BUTTON_REG(x2)                 # Get the button register data
  andi x3, x3, (1<<8)                   # Mask the ISP button
  bnez x3, instr_ex                     # Exit the bootloader if not pressed

  # Load the UART coniguration
setup_uart:
  li x3, F_CPU / BAUD_RATE / 8          # Calculate and load baud rate to x3
  sw x3, UART_CLOCK(x2)                 # Store the baud rate to the uart clock register
  li x3, UART_CONFIGURATION             # Calculate and load uart config to x3
  sw x3, UART_CONFIG(x2)                # Store the config the uart register

  # Display the LED pattern showing that loading mode was initiated
pattern:                                #
  li x4, 0                              # Load zero to the LED state register
  li x5, 15                             # Load 15 to the repeat counter register
pattern_1:                              #
  xori x4, x4, 1                        # Switch the LED state
  sw x4, LED_REG(x2)                    # Store LED state to LED register
  li x3, 0x80000                        # Load the delay counter register
pattern_2:                              #
  addi x3, x3, -1                       # Decrease the delay counter
  bnez x3, pattern_2                    # Continue decreasing until zero reached
  addi x5, x5, -1                       # Decrease the repeat counter
  bnez x5, pattern_1                    # Continue until the repeat counter reaches zero
mem_test:                               #
  li x3, 0x1                            # Set the x3 register for memory test
  sw x3, 16(zero)                       # Store the test data to memory
  li x3, 0x00                           # Clear the x3 register
  lw x3, 16(zero)                       # Load the test data from memory
  sw x3, LED_REG(x2)                    # Display the test data on LEDs

  # Loop the command execution
loop:                                   #
  li x9, 1                              # Preload the counter register
  jal ra, get_uart_data                 # Get the intruction from UART
  addi x3, x3, -'0'                     # Remove the ascii offset from the instruction number
  beqz x3, instr_rd                     # If instruction is 0 jump to the read instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_wr                     # If instruction is 1 jump to the write instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_rd_cnt                 # If instruction is 2 jump to the read instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_wr_cnt                 # If instruction is 3 jump to the write instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_clr                    # If instruction is 4 clear the memory
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_ex                     # If instruction is 5 exit the bootloader
  li x3, 'e'                            # If instruction is unknown prepare the error character
  sw x3, UART_DATA(x2)                  # Send the error character through UART
  j loop                                # Repeat the loop

  # Wipe the whole memory, no questions asked, no data preserved
instr_clr:                              #
  li x3, 0                              # Clear the pointer
  li x4, MEMORY_END                     # Set the end pointer
  li x5, 0x0000006f                     # Set the value to be written (halt, infinite loop)
instr_clr_1:                            #
  sw x5, 0(x3)                          # Store the nop instruction
  addi x3, x3, 4                        # Advance to the next address
  blt x3, x4, instr_clr_1               # Repeat until the end address is reached
  li x3, 'c'                            # Prepare the "clean" message
  sw x3, UART_DATA(x2)                  # Send the "clean" message through UART
  j loop                                # Repeat the loop

  # Read from a given address
instr_rd_cnt:                           #
  li x6, 4                              # Set the 4 characters for count read
  jal ra, get_hex_num                   # Get the count
  mv x9, x7                             # Copy the value to repeat counter
instr_rd:                               #
  li x6, 4                              # Set the 4 characters for address read
  jal ra, get_hex_num                   # Get the address
instr_rd_0:                             #
  lbu x3, 0(x7)                         # Get the value at the given address
  jal ra, print_hex                     # Print the hex value
  addi x7, x7, 1                        # Increase the address pointer
  addi x9, x9, -1                       # Decrease the repeat counter
  bnez x9, instr_rd_0                   # If repeat counter not zero repeat the loop
  j loop                                # Repeat the loop

  # Write the given address
instr_wr_cnt:                           #
  li x6, 4                              # Set the 4 characters for count write
  jal ra, get_hex_num                   # Get the count
  mv x9, x7                             # Copy the value to repeat counter
instr_wr:                               #
  li x6, 4                              # Set the 4 characters for address write
  jal ra, get_hex_num                   # Get the address
  mv x8, x7                             # Copy the address to x8
  li x6, 2                              # Set the 2 characters for the data
instr_wr_0:                             #
  jal ra, get_hex_num                   # Get the write data
  sb x7, 0(x8)                          # Write the byte
  li x3, 'k'                            # Load the 'ok' message to x3
  sw x3, UART_DATA(x2)                  # Send the 'ok' message through UART
  addi x8, x8, 1                        # Increase the address pointer
  addi x9, x9, -1                       # Decrease the repeat counter
  bnez x9, instr_wr_0                   # If repeat counter not zero repeat the loop
  j loop                                # Repeat the loop

  # Exit the bootloader
instr_ex:
  li x3, 's'                            # Load the 'starting' message to x3
  sw x3, UART_DATA(x2)                  # Send the 'starting' message through UART
  mv x3, zero                           # Clear the x3
  sw x3, LED_REG(x2)                    # Clear the regs
  li ra, BLD_ADDRESS                    # Load the bootloader address to the return address
  li sp, MEMORY_END - 4                 # Preload the stack pointer (I'll forget to do this in start.S)
  jr zero                               # Start executing code

  # Get the byte from uart
get_uart_data:                          #
  lw x3, UART_STATUS(x2)                # Load the UART data from status register
  andi x3, x3, 1<<UART_RX_EMPTY         # Mask the RX buffer empty bit
  bnez x3, get_uart_data                # If bit is set check again
  lw x3, UART_DATA(x2)                  # If bit clear get the data from UART
  ret                                   # Return from the subroutine

  # Convert a single character to a hex digit
hex_to_val:                             #
  li x4, 10                             # Load 10 to compare register
  addi x3, x3, -'0'                     # Remove the ASCII digit offset
  blt x3, x4, hex_to_val_1              # Check if it was a digit
  li x4, 16                             # Load 16 to compare register
  addi x3, x3, -('A' - '0' - 10)        # Remove the ASCII uppercase offset
  blt x3, x4, hex_to_val_1              # Check if it was an upparcase digit
  addi x3, x3, -('a' - 'A')             # Remove the ASCII lowercase offset
hex_to_val_1:                           #
  ret                                   # Return from subroutine

  # Convert the value to two hex digits
val_to_hex:                             #
  li x5, '9'                            # Preload '9' character to the compare register
  mv x4, x3                             # Copy the value to x4
  andi x3, x3, 0xF                      # Mask the lower 4 bytes to convert to hex value
  addi x3, x3, '0'                      # Add ASCII digit offset to the value
  ble x3, x5, val_to_hex_1              # If value was a digit skip the next instruction
  addi x3, x3, 'A' - '0' - 10           # Add ASCII uppercase character offset
val_to_hex_1:                           #
  srli x4, x4, 4                        # Shift the upper 4 bits to lower 4 bits
  andi x4, x4, 0xF                      # Mask the lower 4 bytes to convert to hex value
  addi x4, x4, '0'                      # Add ASCII digit offset to the value
  ble x4, x5, val_to_hex_2              # If value was a digit skip the next instruction
  addi x4, x4, 'A' - '0' - 10           # Add ASCII uppercase character offset
val_to_hex_2:                           #
  ret                                   # Return from the subroutine

  # Print the hex value (2 hex digits)
print_hex:                              #
  lw x4, UART_STATUS(x2)                # Load the status register
  andi x4, x4, 1<<UART_TX_EMPTY         # Mask the buffer empty full bit
  beqz x4, print_hex                    # Repeat if the buffer if more than half full
  mv x6, ra                             # Copy the return address to x6
  jal ra, val_to_hex                    # Convert the value to two hex digits
  sw x4, UART_DATA(x2)                  # Send higher hex digit
  sw x3, UART_DATA(x2)                  # Send lower hex digit
  jr x6                                 # Return using the address in x6 (coppied at start)

  # Get a multicharacter hex value
get_hex_num:                            #
  mv x5, ra                             # Copy the return address to x5
  li x7, 0                              # Clear the result register
get_hex_num_1:                          #
  slli x7, x7, 4                        # Shift the value 4 bits left (single hex char)
  jal ra, get_uart_data                 # Get the character from UART
  jal ra, hex_to_val                    # Convert the character to hex
  add x7, x7, x3                        # Add the hex value to tohe result
  addi x6, x6, -1                       # Decrease the character counter
  bnez x6, get_hex_num_1                # If counter didn't reach zero repeat
  jr x5                                 # Return using the address in x5 (coppied at start)
