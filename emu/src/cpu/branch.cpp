/**
 * BRANCH CONDITIONER
 * 
 */

#include "branch.h"

bool branchCalculate(unsigned a, unsigned b, unsigned o) {

    if ((o & 0x1d) == 0x19) {  // JAL and JALR
        return 1;
    }

    if ((o & 0x1F) == 0x18) {  // Branches

        switch ((o >> 5) & 0x7) {
            
            case 0b000:
            if (a == b) return 1; else return 0;

            case 0b001:
            if (a != b) return 1; else return 0;

            case 0b100:
            if ((int)a < (int)b) return 1; else return 0;

            case 0b101:
            if ((int)a >= (int)b) return 1; else return 0;

            case 0b110:
            if (a < b) return 1; else return 0;

            case 0b111:
            if (a >= b) return 1; else return 0;

            default:
            return 0;

        }

    }

    return 0;

}