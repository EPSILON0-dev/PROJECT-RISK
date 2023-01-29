/**
 * Copyright 2023 Lukasz Forenc
 *
 * file: main.c
 *
 * This is a main file of the project template, nothing fancy, just prints
 * "hello world" on uart and sets LED pattern
 */
#define F_CPU 50000000
#define PERLIB_LEDS_IMPL
#define PERLIB_UART_IMPL
#include "../../perlib/leds.h"
#include "../../perlib/uart.h"

int main()
{
  size_t csr_data;

  // Print the hello world
  uart_begin(115200);

  uart_printstring("MISA CSR: 0x");
  uart_printhex(2137, 8, true);

  uart_printstring("\n\rMVENDORID CSR: 0x");
  uart_printhex(2137, 8, true);

  uart_printstring("\n\rMARCHID CSR: 0x");
  uart_printhex(2137, 8, true);

  uart_printstring("\n\rMIMPID CSR: 0x");
  uart_printhex(2137, 8, true);

  uart_printstring("\n\rMHARTID CSR: 0x");
  uart_printhex(2137, 8, true);

  uart_end();

  // Halt and catch fire
  while (1);
}
