/**
 * This is a test for basic cache functionality
 * 
 */

#include "../common/log.h"
#include "../fsb/fsb.h"
#include "../cache/cache.h"

FrontSideBus FSB;
ReadOnlyCache roCache;

int main() 
{
    roCache.read(0x00000055);
    return 0;
}