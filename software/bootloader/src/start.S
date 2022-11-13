#include "hardware.h"

#define UART_CONFIGURATION (2<<UART_LENGTH) | (1<<UART_RX_EN) | (1<<UART_TX_EN)
#define BLD_ADDRESS 0x00007E00
#define BLD_SIZE 0x00000200

.section .text
.fill BLD_ADDRESS / 4, 4, 0x0000006f

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
pattern_l0:                             #
  xori x4, x4, 1                        # Switch the LED state
  sw x4, LED_REG(x2)                    # Store LED state to LED register
  li x3, 0x80000                        # Load the delay counter register
pattern_l1:                             #
  addi x3, x3, -1                       # Decrease the delay counter
  bnez x3, pattern_l1                   # Continue decreasing until zero reached
  addi x5, x5, -1                       # Decrease the repeat counter
  bnez x5, pattern_l0                   # Continue until the repeat counter reaches zero

  # Loop the command execution
loop:                                   #
  jal ra, get_uart_data                 # Get the intruction from UART
  addi x3, x3, -'0'                     # Remove the ascii offset from the instruction number
  beqz x3, instr_rd                     # If instruction is zero jump to the read instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_wr                     # If instruction is one jump to the write instruction
  addi x3, x3, -1                       # Check the next instruction
  beqz x3, instr_ex                     # If instruction is two exit the bootloader
  li x3, 'e'                            # If instruction is unknown prepare the error character
  sw x3, UART_DATA(x2)                  # Send the error character through UART
  j loop                                # Repeat the loop

  # Read a single byte from a given address
instr_rd:                               #
  li x6, 4                              # Set the 4 characters for address read
  jal ra, get_hex_num                   # Get the address
  lbu x3, 0(x7)                         # Get the value at the given address
  jal ra, val_to_hex                    # Convert the value to two hex digits
  sw x4, UART_DATA(x2)                  # Send higher hex digit
  sw x3, UART_DATA(x2)                  # Send lower hex digit
  j loop                                # Repeat the loop

  # Write a single byte to the given address
instr_wr:                               #
  li x6, 4                              # Set the 4 characters for address read
  jal ra, get_hex_num                   # Get the address
  mv x8, x7                             # Copy the address to x8
  li x6, 2                              # Set the 2 characters for the data
  jal ra, get_hex_num                   # Get the write data
  li x6, BLD_ADDRESS                    # Load the bootloader address to compare register
  blt x7, x6, instr_wr_ok               # Check if address isn't bootloader's
  li x6, BLD_ADDRESS + BLD_SIZE         # Load the end of the bootloader to compare register
  bge x7, x6, instr_wr_ok               # Check if address isn't bootloader's
  li x3, 'p'                            # Load the 'protected' message to x3
  sw x3, UART_DATA(x2)                  # Send the 'protected' message through UART
  j loop                                # Repeat the loop
instr_wr_ok:                            #
  sb x7, 0(x8)                          # Write the byte
  li x3, 'k'                            # Load the 'ok' message to x3
  sw x3, UART_DATA(x2)                  # Send the 'ok' message through UART
  j loop                                # Repeat the loop

  # Exit the bootloader
instr_ex:
  li x3, 's'                            # Load the 'starting' message to x3
  sw x3, UART_DATA(x2)                  # Send the 'starting' message through UART
  mv x3, zero                           # Clear the x3
  sw x3, LED_REG(x2)                    # Clear the regs
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
  blt x3, x4, hex_to_val_end            # Check if it was a digit
  li x4, 16                             # Load 16 to compare register
  addi x3, x3, -('A' - '0' - 10)        # Remove the ASCII uppercase offset
  blt x3, x4, hex_to_val_end            # Check if it was an upparcase digit
  addi x3, x3, -('a' - 'A')             # Remove the ASCII lowercase offset
hex_to_val_end:                         #
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

  # Get a multicharacter hex value
get_hex_num:                            #
  mv x5, ra                             # Copy the return address to x5
  li x7, 0                              # Clear the result register
get_hex_num_loop:                       #
  slli x7, x7, 4                        # Shift the value 4 bits left (single hex char)
  jal ra, get_uart_data                 # Get the character from UART
  jal ra, hex_to_val                    # Convert the character to hex
  add x7, x7, x3                        # Add the hex value to tohe result
  addi x6, x6, -1                       # Decrease the character counter
  bnez x6, get_hex_num_loop             # If counter didn't reach zero repeat
  jr x5                                 # Return using the address in x5 (coppied at start)