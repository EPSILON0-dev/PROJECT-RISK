/**
 * This is a file for C++ emulator of the machine
 * 
 * Each block of cache contains 32 bytes so all control array sizes are divided by 32
 * 
 * Address is constructed like this:
 *   26    14   13        5   4         2   1        0
 *  [========] [===========] [===========] [==========]
 *     tag         index         block         byte
 * 
 * Tag memory clock will be run 180 degrees out of phase from main clock,
 *  this will allow to read the cache in only 1 clock cycle
 * 
 * Main array: ____----____----____
 * Tag array:  __----____----____--
 */

#include "log.h"
#include "fsb.h"
#include "cache.h"
#include "config.h"
#include "debug.h"

extern FrontSideBus fsb; 

/**
 * @brief Constructor
 * 
 */
ReadOnlyCache::ReadOnlyCache(void)
{
    // Everything is divided by 2 because there are 2 sets
    memoryArraySet1 = new unsigned[16384 / sizeof(unsigned) / 2];
    tagArraySet1 = new unsigned short[16384 / 32 / 2];
    validArraySet1 = new unsigned char[16384 / 32 / 2];
    lastAccessedArraySet1 = new unsigned char[16384 / 32 / 2];
    memoryArraySet2 = new unsigned[16384 / sizeof(unsigned) / 2];
    tagArraySet2 = new unsigned short[16384 / 32 / 2];
    validArraySet2 = new unsigned char[16384 / 32 / 2];
    lastAccessedArraySet2 = new unsigned char[16384 / 32 / 2];
    cacheStatus = cOk;
}

/**
 * @brief Destructor
 * 
 */
ReadOnlyCache::~ReadOnlyCache(void)
{
    // Delete all arrays
    delete[] memoryArraySet1;
    delete[] tagArraySet1;
    delete[] validArraySet1;
    delete[] lastAccessedArraySet1;
    delete[] memoryArraySet2;
    delete[] tagArraySet2;
    delete[] validArraySet2;
    delete[] lastAccessedArraySet2;
}

/**
 * @brief Read data from cache
 * @param address read address
 * @return Data from memory
 * 
 */
unsigned ReadOnlyCache::read(unsigned address)
{
    // If waiting for requested data, keep waiting
    if (cacheStatus)
        if (fsb.readRequestStatus[0] != fsb.cComplete)
            return 0;

    // Print CACHE_DEBUG message
    #ifdef CACHE_DEBUG
        Log::logSrc("Cache", COLOR_BLUE);
        Log::log("Reading from address ");
        Log::logHex(address, COLOR_MAGENTA, 8);
        Log::log("...\n");
    #endif

    // Decode address
    unsigned block = (address >> 2) & 0x7;
    unsigned tag = address >> 14;
    unsigned index = (address >> 5) & 0xFF;

    // Check both arrays for the tag
    unsigned char hit1, hit2;
    hit1 = (tagArraySet1[index] == tag && validArraySet1[index]);
    hit2 = (tagArraySet2[index] == tag && validArraySet2[index]);

    // Print CACHE_DEBUG message
    #ifdef CACHE_DEBUG
        Log::logSrc("Cache", COLOR_BLUE);
        Log::log("Checking arrays for tag: [1: ");
        Log::log(((hit1)? "hit":"miss"), (hit1)? COLOR_GREEN : COLOR_NONE);
        Log::log("] [2: ");
        Log::log(((hit2)? "hit":"miss"), (hit2)? COLOR_GREEN : COLOR_NONE);
        Log::log("]\n");
    #endif

    // Request data when not found in cache
    if (!hit1 && !hit2) {
        #ifdef CACHE_DEBUG
            Log::logSrc("Cache", COLOR_BLUE);
            Log::log("Data not found in cache, requesting read from main RAM\n");
        #endif

        // Request read
        bool secondSet = (lastAccessedArraySet1[index]) ? 1 : 0;
        fsb.callRead((tag << 14) | (index << 5), 0, secondSet);
        
        // Update tag
        if (secondSet) {
            tagArraySet2[index] = tag;
            validArraySet2[index] = 1;
            lastAccessedArraySet2[index] = 1;
            lastAccessedArraySet1[index] = 0;
        } else {
            tagArraySet1[index] = tag;
            validArraySet1[index] = 1;
            lastAccessedArraySet1[index] = 1;
            lastAccessedArraySet2[index] = 0;
        }
        cacheStatus = cWait;
        return 0;
    } 

    // Read data from cache
    if (hit1) {
        #ifdef CACHE_DEBUG
            Log::logSrc("Cache", COLOR_BLUE);
            Log::log("Reading data from set 1: ");
            Log::logHex(memoryArraySet1[(index << 3) + block], COLOR_MAGENTA, 8);
            Log::log("\n");
            Log::logSrc("Cache", COLOR_BLUE);
            Log::log("Setting block as last used\n");
        #endif

        lastAccessedArraySet1[index] = 1;
        lastAccessedArraySet2[index] = 0;
        return memoryArraySet1[(index << 3) + block];
    } else {
        #ifdef CACHE_DEBUG
            Log::logSrc("Cache", COLOR_BLUE);
            Log::log("Reading data from set 2: ");
            Log::logHex(memoryArraySet2[(index << 3) + block], COLOR_MAGENTA, 8);
            Log::log("\n");
            Log::logSrc("Cache", COLOR_BLUE);
            Log::log("Setting block as last used\n");
        #endif

        lastAccessedArraySet1[index] = 0;
        lastAccessedArraySet2[index] = 1;
        return memoryArraySet2[(index << 3) + block];
    }
}

/**
 * @brief This function allows the FSB to modify cache contents
 * @param address block start address
 * @param data 32 bits of data
 * 
 */
void ReadOnlyCache::fsbWriteCache(unsigned address, unsigned data, bool secondSet)
{
    if (secondSet) 
        memoryArraySet2[address] = data;
    else
        memoryArraySet1[address] = data;
}