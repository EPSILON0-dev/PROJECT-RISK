/**
 * BRANCH CONDITIONER
 * 
 */
#include "../common/config.h"
#include "../common/log.h"
#include "branch.h"



/**
 * @brief Update function for branch conditioner
 * 
 */
void BranchConditioner::Update(void)
{

    n_BranchEnable = 0;
    
    if ((i_OpCode & 0x77) == 0x67) {  // JAL and JALR
        n_BranchEnable = 1;
        return;
    }

    if ((i_OpCode & 0x7F) == 0x63) {  // Branches

        switch ((i_OpCode >> 12) & 0x7) {
            
            case 0b000:
            if (i_RegData1 == i_RegData2)
            n_BranchEnable = 1;
            return;

            case 0b001:
            if (i_RegData1 != i_RegData2)
            n_BranchEnable = 1;
            return;

            case 0b100:
            if (((int)i_RegData1) < ((int)i_RegData2))
            n_BranchEnable = 1;
            return;

            case 0b101:
            if (((int)i_RegData1) >= ((int)i_RegData2))
            n_BranchEnable = 1;
            return;

            case 0b110:
            if (i_RegData1 < i_RegData2)
            n_BranchEnable = 1;
            return;

            case 0b111:
            if (i_RegData1 >= i_RegData2)
            n_BranchEnable = 1;
            return;

            default:
            n_BranchEnable = 0;
            return;

        }

    }

}



/**
 * @brief Update ports function for branch conditioner
 * 
 */
void BranchConditioner::UpdatePorts(void)
{
    o_BranchEnable = n_BranchEnable;
}



/**
 * @brief Logging function for branch conditioner
 * 
 */
void BranchConditioner::log(void)
{
    
    Log::logSrc(" BRANCH  ", COLOR_GREEN);
    if ((i_OpCode & 0x77) == 0x67) {
        Log::log("Unconditional branch\n");
    } else if ((i_OpCode & 0x7F) == 0x63) {
        Log::log("Conditional branch: ");
        Log::log((n_BranchEnable) ? "Taken\n" : "Skipped\n");
    } else {
        Log::log("Irrelevant\n");
    }

}