/**
 * This is a test for basic data cache functionality
 *
 */

#include <iostream>
#include "../common/log.h"
#include "../memory/dcache.h"
#include "../memory/ddr.h"
#include "../memory/fsb.h"

MainRam ddr;
DataCache dCache;
FrontSideBus fsb;

void Update()
{
    dCache.Update();
    ddr.Update();

    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();
}

void UpdateLog()
{
    dCache.log();
    ddr.log();
    fsb.log();

    Update();
    
    Log::log("\n");
}

int main()
{
    fsb.loadPointers((void*)0, &dCache, &ddr);
    Log::log("\n");

    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x20;
    for (unsigned i = 0; i < 20; i++)
        Update();

    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x40;
    for (unsigned i = 0; i < 20; i++)
        Update();

    dCache.i_CacheReadEnable = 1;
    dCache.i_CacheAddress = 0x60;
    for (unsigned i = 0; i < 20; i++)
        Update();

    dCache.i_CacheAddress = 0x20;
    dCache.i_CacheReadEnable = 0;
    dCache.i_CacheWriteEnable = 1;
    UpdateLog();
    dCache.i_CacheAddress = 0x40;
    UpdateLog();
    dCache.i_CacheAddress = 0x44;
    UpdateLog();
    dCache.i_CacheAddress = 0x48;
    UpdateLog();
    dCache.i_CacheAddress = 0x60;
    UpdateLog();
    dCache.i_CacheWriteEnable = 0;
    for (unsigned i = 0; i < 32; i++)
        UpdateLog();

    return 0;
}