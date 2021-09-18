/**
 * This is a test for basic cache functionality
 *
 */

#include <iostream>
#include "icache.h"
#include "dcache.h"
#include "ddr.h"
#include "fsb.h"
#include "log.h"

MainRam ddr;
InstructionCache iCache;
DataCache dCache;
FrontSideBus fsb;

void Update()
{
    iCache.log();
    dCache.log();
    ddr.log();
    fsb.log();

    iCache.Update();
    dCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();

    Log::log("\n");
}

int main()
{
    fsb.loadPointers(&iCache, &dCache, &ddr);
    Log::log("\n");

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x20;
    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x40;
    for (unsigned i = 0; i < 32; i++) {
        Update();
    }

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x4020;
    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x4040;
    for (unsigned i = 0; i < 32; i++) {
        Update();
    }

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x8020;
    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x8040;
    for (unsigned i = 0; i < 32; i++) {
        Update();
    }

    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x4020;
    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x4040;
    Update();

    iCache.i_CacheReadEnable = 0;
    iCache.i_CacheAddress = 0;
    dCache.i_CacheReadEnable = 0;
    dCache.i_CacheAddress = 0;
    Update();

    dCache.i_CacheWriteEnable = 1;
    dCache.i_CacheWriteData = 0x55AA55AA;
    dCache.i_CacheAddress = 0x20;
    for (unsigned i = 0; i < 32; i++) {
        Update();
    }

    dCache.i_CacheWriteEnable = 1;
    dCache.i_CacheWriteData = 0x55AA55AA;
    dCache.i_CacheAddress = 0x4020;
    for (unsigned i = 0; i < 32; i++) {
        Update();
    }


    return 0;
}