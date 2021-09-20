/**
 * This is a test for basic data cache functionality
 *
 */

#include "../common/log.h"
#include "../memory/dcache.h"
#include "../memory/ddr.h"
#include "../memory/fsb.h"

MainRam ddr;
DataCache dCache;
FrontSideBus fsb;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        dCache.log();
        ddr.log();
        fsb.log();
        
        dCache.Update();
        ddr.Update();

        dCache.UpdatePorts();
        ddr.UpdatePorts();

        fsb.Update();
    }
}

int main()
{
    fsb.loadPointers((void*)0, &dCache, &ddr);

    Log::log("\n[>>>>>>>>>] Write cache 0x20\n\n");
    dCache.i_CacheAddress = 0x20;
    dCache.i_CacheReadEnable = 1;
    Update(16);
    dCache.i_CacheReadEnable = 0;
    dCache.i_CacheWriteData = 0x2020;
    dCache.i_CacheWriteEnable = 1;
    Update();
    dCache.i_CacheWriteEnable = 0;
    Update(11);

    Log::log("\n[>>>>>>>>>] Read modified cache 0x20\n\n");
    dCache.i_CacheReadEnable = 1;
    for (unsigned i = 0 ; i < 8; i++) {
        dCache.i_CacheAddress = 0x20 + i * 4;
        Update();
    }

    Log::log("\n[>>>>>>>>>] Changing cached blocks (0x4020 and 0x8020)\n\n");
    dCache.i_CacheAddress = 0x4020;
    dCache.i_CacheReadEnable = 1;
    Update(16);
    dCache.i_CacheAddress = 0x8020;
    dCache.i_CacheReadEnable = 1;
    Update(16);
    dCache.i_CacheAddress = 0x20;
    dCache.i_CacheReadEnable = 1;
    Update(16);

    Log::log("\n[>>>>>>>>>] Read modified cache 0x20\n\n");
    dCache.i_CacheReadEnable = 1;
    for (unsigned i = 0 ; i < 8; i++) {
        dCache.i_CacheAddress = 0x20 + i * 4;
        Update();
    }
    

    return 0;
}