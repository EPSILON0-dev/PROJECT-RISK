/**
 * REGISTER SET
 * 
 */

#include "../common/config.h"
#include "../common/log.h"
#include "regs.h"

RegisterSet::RegisterSet(void)
{
    registerArray = new unsigned[32];
    for (unsigned i = 0; i < 32; i++)
        registerArray[i] = 0;
}

RegisterSet::~RegisterSet(void)
{
    delete[] registerArray;
}

unsigned RegisterSet::regRead(unsigned a)
{

    return registerArray[a];

}

void RegisterSet::regWrite(unsigned a, unsigned d)
{

    registerArray[a] = d;

}

void RegisterSet::log(void)
{

    for (unsigned y = 0; y < 8; y++) {
        Log::logSrc("  REGS   ", COLOR_GREEN);
        for (unsigned x = 0; x < 4; x++) {
            Log::logHex(registerArray[y*4+x], (registerArray[y*4+x])? COLOR_GREEN : COLOR_BLUE, 8);
            Log::log(" ");
        }
        Log::log("\n");
    }

}