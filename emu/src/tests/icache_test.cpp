/**
 * This is a test for basic instruction cache functionality
 *
 */

#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/ddr.h"
#include "../memory/fsb.h"

MainRam ddr;
InstructionCache iCache;
FrontSideBus fsb;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        iCache.log();
        ddr.log();
        fsb.log();

        iCache.Update();
        ddr.Update();

        iCache.UpdatePorts();
        ddr.UpdatePorts();

        fsb.Update();
    }
}

int main()
{
    fsb.loadPointers(&iCache, (void*)0, &ddr);

    Log::log("\n[>>>>>>>>>] Read cache set 2\n\n");
    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x20;
    Update(20);

    Log::log("\n[>>>>>>>>>] Read cache set 1\n\n");
    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x4020;
    Update(20);

    Log::log("\n[>>>>>>>>>] Read cache set 2\n\n");
    iCache.i_CacheReadEnable = 1;
    iCache.i_CacheAddress = 0x8020;
    Update(20);

    return 0;
}