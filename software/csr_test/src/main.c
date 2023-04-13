
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <math.h>
#include "../include/hardware.h"

#define F_CPU       10000000ULL
#define BAUD_RATE   115200
#define MAX_PRIME   10000

void uart_setup(void)
{
  UART_CONFIG = (1 << UART_TX_EN) | (3 << UART_LENGTH);
  UART_CLOCK = F_CPU / BAUD_RATE / 8;
}

void uart_print(const char *string)
{
  size_t i = 0;
  while (1) {
    while (UART_STATUS & (1 << UART_TX_FULL));
    UART_DATA = string[i];
    if (string[i++] == 0) break;
  }
}

int main(void)
{
  uart_setup();
  char buffer[64];
  unsigned result;

  sprintf(buffer, "Jak niewiele nam potrzeba, by naprawic zgnily swiat\n");
  uart_print(buffer);

  asm("csrr %0, 0x301" : "=r"(result));
  sprintf(buffer, "MISA:      %08X\n", result);
  uart_print(buffer);
  asm("csrr %0, 0xF11" : "=r"(result));
  sprintf(buffer, "MVENDORID: %08X\n", result);
  uart_print(buffer);
  asm("csrr %0, 0xF12" : "=r"(result));
  sprintf(buffer, "MARCHID:   %08X\n", result);
  uart_print(buffer);
  asm("csrr %0, 0xF13" : "=r"(result));
  sprintf(buffer, "MIMPID:    %08X\n", result);
  uart_print(buffer);
  asm("csrr %0, 0xF14" : "=r"(result));
  sprintf(buffer, "MHARTID:   %08X\n", result);
  uart_print(buffer);

  while (1);
}
