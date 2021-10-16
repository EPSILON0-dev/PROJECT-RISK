/**
 * DECODE
 * 
 */
#include <string>
#include "decode.h"
#include "../common/config.h"
#include "../common/log.h"

unsigned getFormat(unsigned op)
{
    switch (op & 0x7F) {
        
        // Format U
        case 0b0110111: 
        case 0b0010111: 
        return FormatU;

        // Format J
        case 0b1100111:
        return FormatJ;

        // Format B
        case 0b1100011:
        return FormatB;

        // Format I
        case 0b0000011:
        case 0b0010011:
        return FormatI;

        // Format S
        case 0b0100011:
        return FormatI;
        
        // Format R
        case 0b0110011:
        return FormatR;

        // Invalid format
        default: 
        return 6;

    }
}

unsigned getImmediate(unsigned op)
{
    switch (getFormat(op)) {
        
        default:
        return 0;

        case FormatI:
        return ((op >> 31)? 0xFFFFF000 : 0) | op >> 20;

        case FormatS:
        return ((op >> 31)? 0xFFFFF000 : 0) | ((op >> 20) & 0xFE0) | (op & 0x1E);

        case FormatB:
        return (((op >> 31) ? 0xFFFFF000 : 0x0) | ((op << 4) & 0x800) | 
            ((op >> 20) & 0x7E0) | ((op >> 7) & 0x1E));

        case FormatU: 
        return (op & 0xFFFFF000);

        case FormatJ:
        return ((op >> 31)? 0xFFF00000 : 0) | ((op >> 20) & 0x7FE) | 
            ((op >> 9) & 0xF00) | (op & 0xFF000); 

    }
}

unsigned getRs1(unsigned op)
{
    return (op >> 15) & 0x1F;
}

unsigned getRs2(unsigned op)
{
    return (op >> 20) & 0x1F;
}

unsigned getRd(unsigned op)
{
    return (op >> 7) & 0x1F;
}

unsigned getOpcode(unsigned op)
{
    return (op >> 2) & 0x1F;
}

unsigned getFunct3(unsigned op)
{
    return (op >> 12) & 0x7;
}