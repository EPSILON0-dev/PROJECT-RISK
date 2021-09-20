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
 * @brief This function performs an ALU operation
 * 
 */
unsigned ArythmeticLogicUnit::execute(void)
{
    switch (i_OpCode3) 
    {
        default:  // Add
        if (!i_Immediate && i_OpCode7 == 0x20) {
            return i_InputA - i_InputB;
        } else {
            return i_InputA + i_InputB;
        }

        case cSLL:  // Shift Left Logical
        return i_InputA << i_InputB;

        case cSLT:  // Set Lower Than
        return ((int)i_InputA < (int)i_InputB) ? 1 : 0;

        case cSLTU:  // Set Lower Than (Unsigned)
        return ((unsigned)i_InputA < (unsigned)i_InputB) ? 1 : 0;

        case cXOR:  // Logical Exclusiwe Or
        return i_InputA ^ i_InputB;

        case cSRL:  // Shift Right Logical
        if (i_OpCode7 == 0x20) {
            return (unsigned)((int)i_InputA >> i_InputB);
        } else {
            return (unsigned)i_InputA >> i_InputB;
        }

        case cOR:  // Logical Or
        return i_InputA | i_InputB;

        case cAND:  // Logical And
        return i_InputA & i_InputB;
    }
}



/**
 * @brief Update function for ALU
 * 
 */
void ArythmeticLogicUnit::Update(void)
{
    n_Output = execute();
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
    Log::log(" --> ");
    Log::logHex(execute(), COLOR_MAGENTA, 8);
    Log::log("\n");

}