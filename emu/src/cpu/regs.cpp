/**
 * REGISTER SET
 * 
 */
#include "../common/config.h"
#include "../common/log.h"
#include "regs.h"


RegisterSet::RegisterSet(void)
{
    regs = new unsigned[32];
    for (unsigned i = 0; i < 32; i++)
        regs[i] = 0;
}


/**
 * @brief Read from register set
 * 
 * @param a Read address
 * 
 * @return Data from register set
 */
unsigned RegisterSet::read(unsigned a)
{
    return regs[a];
}


/**
 * @brief Write to register set
 * 
 * @param a Write address
 * @param d Write data
 */
void RegisterSet::write(unsigned a, unsigned d)
{
    regs[a] = d;
}


/**
 * @brief Print out the contents of the registers 
 * 
 */
void RegisterSet::log(void)
{
    for (unsigned y = 0; y < 8; y++) {
        Log::logSrc("  REGS   ", COLOR_GREEN);
        for (unsigned x = 0; x < 4; x++) {
            Log::logHex(regs[y*4+x], (regs[y*4+x])? COLOR_GREEN : COLOR_BLUE, 8);
            Log::log(" ");
        }
        Log::log("\n");
    }
}