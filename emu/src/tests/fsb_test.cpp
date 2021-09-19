/**
 * This is a test for basic data cache functionality
 *
 */

#include <iostream>
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"
#include "../memory/ddr.h"
#include "../memory/fsb.h"

MainRam ddr;
InstructionCache iCache;
DataCache dCache;
FrontSideBus fsb;

void Update()
{
    iCache.Update();
    dCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();
}

void UpdateLog()
{
    iCache.log();
    dCache.log();
    ddr.log();
    fsb.log();

    Update();
    
    Log::log("\n");
}

int main()
{
    fsb.loadPointers(&iCache, &dCache, &ddr);
    Log::log("\n");

    dCache.i_CacheReadEnable = 1;
    for (unsigned i = 0; i < 64; i++) {
        dCache.i_CacheAddress = i * 0x20;
        for (unsigned j = 0; j < 20; j++)
            Update();
    }

    dCache.i_CacheAddress = 0x20;
    dCache.i_CacheReadEnable = 0;
    dCache.i_CacheWriteEnable = 1;
    for (unsigned i = 0; i < 33; i++) {
        dCache.i_CacheAddress = i * 0x20;
        Update();
    }

    UpdateLog();
    dCache.i_CacheAddress = 34 * 0x20;
    dCache.i_CacheWriteEnable = 1;
    iCache.i_CacheReadEnable = 1;
    UpdateLog();
    dCache.i_CacheWriteEnable = 0;
    for (unsigned i = 0; i < 320; i++)
        UpdateLog();

    return 0;
}