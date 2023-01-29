/**
 * Copyright 2023 Lukasz Forenc
 *
 * file: main.c
 *
 * This is a main file of the prime generator, it generates prime numbers.
 */
#define F_CPU 50000000
#define PERLIB_LEDS_IMPL
#define PERLIB_UART_IMPL
#include "../../perlib/leds.h"
#include "../../perlib/uart.h"

#define MAX_PRIME 100000

int main()
{
  // Print primes
  uart_begin(115200);
  uart_printstring("RV32IMC primes generator, generating ");
  uart_printunsigned(MAX_PRIME);
  uart_printstring(" primes:\n\r");
  for (int num = 2; num < MAX_PRIME; num++) {
    bool prime = true;
    for (int div = 2; div < num / 2 + 1; div++) {
      if (num % div == 0) {
        prime = false;
        break;
      }
    }
    if (prime) {
      uart_printunsigned(num);
      uart_printchar(' ');
    }
  }
  uart_printstring("\n\rDone.\n\r");
  uart_end();

  // Halt and catch fire
  while (1);
}
