#include <stddef.h>
#include "../include/hardware.h"

#define F_CPU       10000000ULL
#define BAUD_RATE   115200

int main(void)
{
  UART_CONFIG = (1 << UART_TX_EN) | (3 << UART_LENGTH);
  UART_CLOCK = F_CPU / BAUD_RATE / 8;

  const char *string = "Hello World!\n\r";

  size_t i = 0;
  while (string[i] != 0) {
    while (!(UART_STATUS & (1 << UART_TX_EMPTY)));
    UART_DATA = string[i++];
  }

  while (1);
}