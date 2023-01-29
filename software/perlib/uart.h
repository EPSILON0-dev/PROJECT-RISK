#ifndef __PERLIB_UART_H
#define __PERLIB_UART_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>
#include "io_address.h"
#include "leds.h"

#define F_CPU 50000000
#define PERLIB_UART_IMPL

#ifdef PERLIB_UART_IMPL
#define DEFAULT_LENGTH          8
#define DEFAULT_PARITY          false
#define DEFAULT_ODD             false
#define DEFAULT_DOUBLESTOP      false
#endif

void uart_enable(void);
void uart_disable(void);
void uart_setbaudrate(size_t baud_rate);
void uart_setlength(size_t data_length);
void uart_setstopbits(bool double_stop);
void uart_setparity(bool parity, bool odd);
void uart_begin(size_t baud_rate);
void uart_end(void);

void uart_cleartxbuffer(void);
void uart_clearrxbuffer(void);

bool uart_checkrxbuffer(void);
bool uart_checkrxerror(void);
uint16_t uart_read(void);
char uart_readchar(void);

void uart_write(uint16_t chr);
void uart_printchar(char chr);
void uart_printstring(const char *string);
void uart_printunsigned(uint32_t num);
void uart_printint(int32_t num);
void uart_printhex(uint32_t num, size_t length, bool capital);

#ifdef PERLIB_UART_IMPL

#define UART_CLOCK DEF_REG32(UART_CLOCK_ADDRESS)
#define UART_CONFIG DEF_REG32(UART_CONFIG_ADDRESS)
#define UART_STATUS DEF_REG32(UART_STATUS_ADDRESS)
#define UART_DATA DEF_REG32(UART_DATA_ADDRESS)

#ifndef F_CPU
#error CPU frequency (F_CPU) must be defined in the uart implementation file
#endif

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_enable(void)
{
  UART_CONFIG |= ((1 << UART_TX_EN) | (1 << UART_RX_EN));
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_disable(void)
{
  UART_CONFIG &= ~((1 << UART_TX_EN) | (1 << UART_RX_EN));
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_setbaudrate(size_t baud_rate)
{
  UART_CLOCK = F_CPU / baud_rate / 8;
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_setlength(size_t data_length)
{
  if (data_length < 6 || data_length > 9)
    return;

  UART_CONFIG &= ~(0b11 << UART_LENGTH);
  UART_CONFIG |= ((data_length - 6) << UART_LENGTH);
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_setstopbits(bool double_stop)
{
  if (double_stop) {
    UART_CONFIG |= (1 << UART_2STOP);
  } else {
    UART_CONFIG &= ~(1 << UART_2STOP);
  }
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_setparity(bool parity, bool odd)
{
  if (parity) {
    UART_CONFIG |= (1 << UART_PARITY);
  } else {
    UART_CONFIG &= ~(1 << UART_PARITY);
  }

  if (odd) {
    UART_CONFIG |= (1 << UART_ODD);
  } else {
    UART_CONFIG &= ~(1 << UART_ODD);
  }
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_begin(size_t baud_rate)
{
  uart_enable();
  uart_setbaudrate(baud_rate);
  uart_setlength(DEFAULT_LENGTH);
  uart_setparity(DEFAULT_PARITY, DEFAULT_ODD);
  uart_setstopbits(DEFAULT_DOUBLESTOP);
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_end(void)
{
  while (!(UART_STATUS & (1 << UART_TX_EMPTY)));
  uart_disable();
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_cleartxbuffer(void)
{
  UART_CONFIG |= (1 << UART_TX_CLEAR);
}
// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_clearrxbuffer(void)
{
  UART_CONFIG |= (1 << UART_RX_CLEAR);
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
bool uart_checkrxbuffer(void)
{
  return !(UART_STATUS & (1 << UART_RX_EMPTY));
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
bool uart_checkrxerror(void)
{
  return !!(UART_STATUS & ((1 << UART_OVERRUN_ERR) | (1 << UART_PARITY_ERR)));
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
uint16_t uart_read(void)
{
  return (uint16_t)UART_DATA;
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
char uart_readchar(void)
{
  return (char)UART_DATA;
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_write(uint16_t chr)
{
  while (UART_STATUS & (1 << UART_TX_HALF));
  UART_DATA = (uint32_t)chr;
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_printchar(char chr)
{
  uart_write((uint16_t)chr);
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_printstring(const char *string)
{
  while (*string) {
    uart_printchar(*string);
    string++;
  }
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_printunsigned(uint32_t num)
{
  int digits = 1;
  int div = 1;
  while (num / div >= 10) {
    digits++;
    div *= 10;
  }

  while (digits--) {
    uart_printchar(num / div % 10 + '0');
    div /= 10;
  }
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_printint(int32_t num)
{
  if (num < 0) {
    uart_printchar('-');
    num = -num;
  }

  uart_printunsigned(num);
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void uart_printhex(uint32_t num, size_t length, bool capital)
{
  length = (length > 8) ? 8 : length;
  while (length--) {
    int dig = (num >> ((length - 1) * 4)) & 0xF;
    dig += (dig > 9) ? ((capital) ? ('A' - 10) : ('a' - 10)) : '0';
    uart_printchar(dig);
  }
}

#endif
#endif
