/**
 * This is a test for basic cache functionality
 *
 */

#include "cache.h"
#include "ddr.h"
#include "fsb.h"
#include "log.h"

FrontSideBus fsb;
ReadOnlyCache roCache;
DDR ddr;

int main()
{
    roCache.read(0x00000055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00100055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00000055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00100055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00200055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00200055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00300055);
    for (int i = 0; i < 64; i++)
        { fsb.Update(); ddr.Update(); }
    Log::log("\n");

    roCache.read(0x00300055); Log::log("\n");

    return 0;
}
