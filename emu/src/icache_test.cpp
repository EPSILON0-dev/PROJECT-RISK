/**
 * This is a test for basic instruction cache functionality
 *
 */

#include <iostream>
#include "icache.h"
#include "ddr.h"
#include "fsb.h"
#include "log.h"

MainRam ddr;
InstructionCache iCache;
FrontSideBus fsb;

void Update()
{
    iCache.log();
    ddr.log();
    fsb.log();

    iCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();

    Log::log("\n");
}

int main()
{
    fsb.loadPointers(&iCache, (void*)0, &ddr);
    Log::log("\n");

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x20;
    for (unsigned i = 0; i < 20; i++)
        Update();

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x4020;
    for (unsigned i = 0; i < 20; i++)
        Update();

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x8020;
    for (unsigned i = 0; i < 20; i++)
        Update();

    return 0;
}