#ifndef __PERLIB_LEDS_H
#define __PERLIB_LEDS_H

#include <stdint.h>
#include <stdbool.h>
#include "io_address.h"


void leds_setled(uint8_t led, bool value);
void leds_setall(uint8_t led_values);

#ifdef PERLIB_LEDS_IMPL

#define LEDS_REG DEF_REG32(LEDS_ADDRESS)

// NOLINTNEXTLINE(misc-definitions-in-headers)
void leds_setled(uint8_t led, bool value)
{
  if (value) {
    LEDS_REG |= 1 << led;
  } else {
    LEDS_REG &= ~(1 << led);
  }
}

// NOLINTNEXTLINE(misc-definitions-in-headers)
void leds_setall(uint8_t led_values)
{
  LEDS_REG = led_values;
}

#endif
#endif