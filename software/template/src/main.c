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
  // Set the pattern
  leds_setall(0b01111110);

  // Print the hello world
  uart_begin(115200);
  uart_printstring("Hello, World!\n\r");
  uart_end();

  // Halt and catch fire
  while (1);
}
