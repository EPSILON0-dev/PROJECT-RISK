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
    roCache.read(0x00000055);
    return 0;
}