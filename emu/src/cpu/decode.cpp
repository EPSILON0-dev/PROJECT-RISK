/**
 * @file branch.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Instruction decoder
 * @date 2021-10-03
 * 
 */


#include <string>
#include "decode.h"
#include "../common/config.h"
#include "../common/log.h"


enum eFormat { FormatR, FormatI, FormatS, FormatB, FormatU, FormatJ };


/**
 * @brief Get the format of the operations
 * 
 * @param op opcode 
 * @return Format from the eFormat enum 
 */
unsigned getFormat(unsigned op)
{
    switch (op & 0x7F) {
        
        // Format U
        case 0b0110111: 
        case 0b0010111: 
        return FormatU;

        // Format J
        case 0b1101111:
        return FormatJ;

        // Format B
        case 0b1100011:
        return FormatB;

        // Format I
        case 0b0000011:
        case 0b0010011:
        case 0b1100111:
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


/**
 * @brief Get the immediate part of the opcode
 * 
 * @param op opcode
 * @return Immediate value 
 */
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
            ((op >> 9) & 0x100) | (op & 0xFF000); 

    }
}


unsigned getRs1(unsigned op) { return (op >> 15) & 0x1F; }
unsigned getRs2(unsigned op) { return (op >> 20) & 0x1F; }
unsigned getRd(unsigned op) { return (op >> 7) & 0x1F; }
unsigned getOpcode(unsigned op) { return (op >> 2) & 0x1F; }
unsigned getFunct3(unsigned op) { return (op >> 12) & 0x7; }