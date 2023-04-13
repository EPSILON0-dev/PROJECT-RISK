#include <stdint.h>
#define __REG32(x)        *(uint32_t*)(x)

#define UART_CLOCK        __REG32(0x8000)
#define UART_CONFIG       __REG32(0x8004)
#define UART_STATUS       __REG32(0x8008)
#define UART_DATA         __REG32(0x800C)
#define LED_REG           __REG32(0x8010)
#define BUTTON_REG        __REG32(0x8010)

#define UART_TX_EN        0
#define UART_RX_EN        1
#define UART_PARITY       2
#define UART_ODD          3
#define UART_2STOP        4
#define UART_LENGTH       5
#define UART_TX_CLEAR     7
#define UART_RX_CLEAR     8

#define UART_OVERRUN_ERR  0
#define UART_PARITY_ERR   1
#define UART_TX_EMPTY     2
#define UART_TX_HALF      3
#define UART_TX_FULL      4
#define UART_RX_EMPTY     5
#define UART_RX_HALF      6
#define UART_RX_FULL      7