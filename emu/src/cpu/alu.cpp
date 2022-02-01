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

    if (o & 0x20)
    {
        switch (o & 0x7)
        {
        default: // Add / Subtract
            return (!(o & 0x10) && (o & 0x8))? a - b : a + b;

        case 1:  // Shift Left Logical
            return a << b;

        case 2:  // Set Lower Than
            return bool((int)a < (int)b);

        case 3:  // Set Lower Than (Unsigned)
            return bool((unsigned)a < (unsigned)b);

        case 4:  // Logical Exclusive Or
            return a ^ b;

        case 5:  // Shift Right Logical
            return (o & 0x8)? (unsigned)((int)a >> b) : (unsigned)(a >> b);

        case 6:  // Logical Or
            return a | b;

        case 7:  // Logical And
            return a & b;
        }
    }

    return a + b;

}
