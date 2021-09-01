/**
 * This is a test for basic cache functionality
 * 
 */

#include "log.h"
#include "fsb.h"
#include "cache.h"

FrontSideBus FSB;
ReadOnlyCache roCache;

int main() 
{
    roCache.read(0x00000055); Log::log("\n");
    for (int i = 0; i < 16; i++) FSB.Update();

    roCache.read(0x00100055); Log::log("\n");
    for (int i = 0; i < 16; i++) FSB.Update();

    roCache.read(0x00000055); Log::log("\n");
    for (int i = 0; i < 16; i++) FSB.Update();

    roCache.read(0x00100055); Log::log("\n");
    for (int i = 0; i < 16; i++) FSB.Update();

    roCache.read(0x00200055); Log::log("\n");
    for (int i = 0; i < 16; i++) FSB.Update();

    roCache.read(0x00200055); Log::log("\n");
    
    return 0;
}