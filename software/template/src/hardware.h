#include <stdint.h>
#define DEF_REG32(x) (*(volatile uint32_t*)(x))

#define IO_BLOCK          DEF_REG32(0x00008000)
#define UART_CLOCK        DEF_REG32(0x00008000)
#define UART_CONFIG       DEF_REG32(0x00008004)
#define UART_STATUS       DEF_REG32(0x00008008)
#define UART_DATA         DEF_REG32(0x0000800C)
#define LED_REG           DEF_REG32(0x00008010)
#define BUTTON_REG        DEF_REG32(0x00008010)

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