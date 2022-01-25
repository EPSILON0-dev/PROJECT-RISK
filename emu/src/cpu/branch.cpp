/**
 * @file branch.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Branch conditioning functions
 * @date 2021-10-04
 * 
 */


#include "branch.h"


/**
 * @brief Calculate if branch should be taken
 * 
 * @param a Compare register A
 * @param b Compare register B
 * @param o funct3 [14:12] and opcode [6:2]
 * @return Branch enable
 */
bool branch(unsigned a, unsigned b, unsigned o) {

    if ((o & 0x1d) == 0x19) return 1;  // JAL and JALR

    if ((o & 0x1F) == 0x18)  // Branches
    {  
        switch ((o >> 5) & 0x7) 
        {   
            case 0b000: if (a == b) return 1; else return 0;
            case 0b001: if (a != b) return 1; else return 0;
            case 0b100: if ((int)a < (int)b) return 1; else return 0;
            case 0b101: if ((int)a >= (int)b) return 1; else return 0;
            case 0b110: if (a < b) return 1; else return 0;
            case 0b111: if (a >= b) return 1; else return 0;
            default: return 0;
        }
    }

    return 0;  // Everything else

}