/**
 * PROGRAM COUNTER
 * 
 */
#include "../common/config.h"
#include "../common/log.h"
#include "pc.h"



/**
 * @brief Update function for program counter
 * 
 */
void ProgramCounter::Update(void)
{
    if (i_ClockEnable) {
        if (i_Reset) {
            n_Address = 0;
        } else {
            if (i_Branch) {
                n_Address = i_BranchAddress;
            } else {
                n_Address += 0x4;
            }
        }
    }
}



/**
 * @brief Update ports function for program counter
 * 
 */
void ProgramCounter::UpdatePorts(void)
{
    o_Address = n_Address;
}



/**
 * @brief Log function for program counter
 * 
 */
void ProgramCounter::log(void)
{
    Log::logSrc("   PC    ", COLOR_GREEN);
    Log::logHex(n_Address, COLOR_MAGENTA, 8);
    Log::log(" --> ");
    if (i_ClockEnable) {
        if (i_Branch) {
            Log::logHex(i_BranchAddress, COLOR_MAGENTA, 8);
        } else {
            Log::logHex(n_Address + 4, COLOR_MAGENTA, 8);
        }
    } else {
        Log::logHex(n_Address, COLOR_MAGENTA, 8);
    }
    Log::log("\n");
}