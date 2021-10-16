/**
 * ARYTHMETIC AND LOGIC UNIT
 * 
 */

#include "alu.h"

unsigned aluCalculate(unsigned a, unsigned b, unsigned o)
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