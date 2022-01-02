/**
 * @file alu.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief ALU functions
 * @date 2021-09-20
 * 
 */


#include "alu.h"


/**
 * @brief Do a single operation on ALU, 
 *  if ALU is not enabled (o[5]) simple ADD is performed,
 *  Imm (o[4]) determines if funct7 (o[3]) should change the operation 
 * 
 * @param a Input A
 * @param b Input B
 * @param o Command input [5]: Enable [4]: Imm [3]: funct7 [2:0]: funct3
 * @return Result of the operation
 */
unsigned alu(unsigned a, unsigned b, unsigned o)
{

    if (o & 0x20) {
        switch (o & 0x7) 
        {
        default: // Add / Subtract
            if (!(o & 0x10) && (o & 0x8)) {
                return a - b;
            } else {
                return a + b;
            }

        case 1:  // Shift Left Logical
            return a << b;

        case 2:  // Set Lower Than
            return ((int)a < (int)b) ? 1 : 0;

        case 3:  // Set Lower Than (Unsigned)
            return ((unsigned)a < (unsigned)b) ? 1 : 0;

        case 4:  // Logical Exclusiwe Or
            return a ^ b;

        case 5:  // Shift Right Logical
            if (!(o & 0x10) && (o & 0x8)) {
                return (unsigned)((int)a >> b);
            } else {
                return (unsigned)a >> b;
            }

        case 6:  // Logical Or
            return a | b;

        case 7:  // Logical And
            return a & b;
        }
    }

    return a + b;

}