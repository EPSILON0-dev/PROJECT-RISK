/**
 * ARYTHMETIC AND LOGIC UNIT
 * 
 * Logical and arythmetic operations will be realized on standard logic
 * Bit shift operations will be based on shared barrel shifter
 * 
 */

#include "../common/config.h"
#include "../common/log.h"
#include "alu.h"



/**
 * @brief Update function for ALU
 * 
 */
void ArythmeticLogicUnit::Update(void)
{

    switch (i_OpCode3) 
    {
        default:  // Add
        if (!i_Immediate && i_OpCode7 == 0x20) {
            n_Output = i_InputA - i_InputB;
        } else {
            n_Output = i_InputA + i_InputB;
        }
        break;

        case cSLL:  // Shift Left Logical
        n_Output = i_InputA << i_InputB;
        break;

        case cSLT:  // Set Lower Than
        n_Output = ((int)i_InputA < (int)i_InputB) ? 1 : 0;
        break;

        case cSLTU:  // Set Lower Than (Unsigned)
        n_Output = ((unsigned)i_InputA < (unsigned)i_InputB) ? 1 : 0;
        break;

        case cXOR:  // Logical Exclusiwe Or
        n_Output = i_InputA ^ i_InputB;
        break;

        case cSRL:  // Shift Right Logical
        if (i_OpCode7 == 0x20) {
            n_Output = (unsigned)((int)i_InputA >> i_InputB);
        } else {
            n_Output = (unsigned)i_InputA >> i_InputB;
        }
        break;

        case cOR:  // Logical Or
        n_Output = i_InputA | i_InputB;
        break;

        case cAND:  // Logical And
        n_Output = i_InputA & i_InputB;
        break;
    }

}



/**
 * @brief Update ports function for ALU
 * 
 */
void ArythmeticLogicUnit::UpdatePorts(void)
{
    o_Output = n_Output;
}



/**
 * @brief Log function
 * 
 */
void ArythmeticLogicUnit::log(void)
{
    Log::logSrc("   ALU   ", COLOR_GREEN);
    Log::logHex(i_InputA, COLOR_MAGENTA, 8);
    
    switch (i_OpCode3) 
    {
        default:
        Log::log(((!i_Immediate && (i_OpCode7 == 0x20))? "  -  " : "  +  "));
        break;

        case cSLL:
        Log::log(" <<  ");
        break;

        case cSLT:
        case cSLTU:
        Log::log("  <  ");
        break;

        case cXOR:
        Log::log("  ^  ");
        break;

        case cSRL:
        Log::log("  >> ");
        break;

        case cOR:
        Log::log("  |  ");
        break;

        case cAND:
        Log::log("  &  ");
        break;
    }
    
    Log::logHex(i_InputB, COLOR_MAGENTA, 8);
    Log::log(" = ");
    Log::logHex(n_Output, COLOR_MAGENTA, 8);
    Log::log("\n");

}