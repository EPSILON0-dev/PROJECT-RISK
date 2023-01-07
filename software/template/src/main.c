#include "hardware.h"

#define F_CPU       50000000
#define BUAD_RATE   115200

const char message[] = "Hello, World!\n\r\0";

int main()
{
  // Set the clock
  UART_CLOCK = F_CPU / BUAD_RATE / 8;

  // Enable UART
  UART_CONFIG = (1 << UART_TX_EN) | (2 << UART_LENGTH);

  // Show test pattern on the LEDs
  LED_REG = 0x55;

  // Write the message
  int i = 0;
  while (message[i] != '\0') {

    // Wait for the buffer to be empty
    while (!(UART_STATUS & (1 << UART_TX_EMPTY)));

    // Print the character
    UART_DATA = (uint32_t)message[i++];
  }

  while (1);
}