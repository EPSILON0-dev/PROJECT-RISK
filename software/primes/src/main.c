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
  while (string[i] != 0) {
    while (!(UART_STATUS & (1 << UART_TX_EMPTY)));
    UART_DATA = string[i++];
  }
}

bool is_prime(int n)
{
  if (n < 2) {
    return false;
  }
  for (int i = 2; i <= ceil(sqrt(n)); i++) {
    if (n % i == 0) {
      return false;
    }
  }
  return true;
}

int main(void)
{
  uart_setup();
  char buffer[64];

  for (int i = 2; i <= MAX_PRIME; i++) {
    if (is_prime(i)) {
      sprintf(buffer, "%d ", i);
      uart_print(buffer);
    }
  }

  while (1);
}