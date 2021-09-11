/**
 * This is a test for basic cache functionality
 *
 */

#include "icache.h"
#include "dcache.h"
#include "ddr.h"
#include "fsb.h"
#include "log.h"

DDR ddr;
InstructionCache iCache;
DataCache dCache;
FrontSideBus fsb;

int main()
{
    fsb.init(&iCache, &dCache, &ddr);
    Log::log("\n");

    iCache.read(0x00000055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00100055);
    dCache.read(0x00100055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00000055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00100055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    dCache.read(0x00100055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00200055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00200055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00300055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    iCache.read(0x00300055); Log::log("\n");

    return 0;
}
