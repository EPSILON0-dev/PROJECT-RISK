/**
 * INSTRUCTION CACHE
 * 
 * Each block of cache contains 32
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

#include "../common/config.h"
#include "../common/log.h"
#include "icache.h"



/**
 * @brief Constructor
 * 
 */
InstructionCache::InstructionCache(void)
{
    caches1 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) caches1[i] = 0;
    tags1 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tags1[i] = 0;
    valid1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid1[i] = 0;
    caches2 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) caches2[i] = 0;
    tags2 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tags2[i] = 0;
    valid2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid2[i] = 0;
    lastSet = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) lastSet[i] = 0;
    fetchSet = 0;

    i_CacheAddress = 0;
    i_CacheReadEnable = 0;
    i_FsbAddress = 0;
    i_FsbWriteData = 0;
    i_FsbWriteEnable = 0;
    i_FsbLastAccess = 0;

    n_CacheReadData = 0;
    n_CacheValidData = 0;
    n_CacheFetching = 0;

    o_CacheReadData = 0;
    o_CacheValidData = 0;
    o_CacheFetching = 0;
}



/**
 * @brief Destructor
 * 
 */
InstructionCache::~InstructionCache(void)
{
    delete[] caches1;
    delete[] caches2;
    delete[] tags1;
    delete[] tags2;
    delete[] valid1;
    delete[] valid2;
    delete[] lastSet;
}



unsigned InstructionCache::getBlock(unsigned a)
{
    return (a >> 2) & 0x7FF;
}

unsigned InstructionCache::getIndex(unsigned a)
{
    return (a >> 5) & 0xFF;
}

unsigned InstructionCache::getTag(unsigned a)
{
    return (a >> 14);
}

bool InstructionCache::checkCache1(unsigned a)
{
    return (tags1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]);
}

bool InstructionCache::checkCache2(unsigned a)
{
    return (tags2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]);
}



/**
 * @brief Update function for data cache
 * 
 */
void InstructionCache::Update(void)
{

    unsigned block = getBlock(i_CacheAddress);
    unsigned index = getIndex(i_CacheAddress);

    if (i_FsbReadAck) {
        n_FsbReadRequest = 0;
    }

    if (n_CacheFetching && i_FsbWriteEnable) {  // Handle fetching from RAM
        
        if (fetchSet) {
            caches2[getBlock(i_FsbAddress)] = i_FsbWriteData;
            tags2[getIndex(i_FsbAddress)] = getTag(i_FsbAddress);
            valid2[getIndex(i_FsbAddress)] = 1;
            lastSet[getIndex(i_FsbAddress)] = 1;
        } else {
            caches1[getBlock(i_FsbAddress)] = i_FsbWriteData;
            tags1[getIndex(i_FsbAddress)] = getTag(i_FsbAddress);
            valid1[getIndex(i_FsbAddress)] = 1;
            lastSet[getIndex(i_FsbAddress)] = 0;
        }
    
        if (i_FsbLastAccess) {
            n_CacheFetching = 0;
        }

        goto endUpdate;

    }

    if (i_CacheReadEnable && !n_CacheFetching) {  // Handle reads

        if (!(checkCache1(i_CacheAddress) || checkCache2(i_CacheAddress))) {
            goto fetchFromRam;
        }

        if (checkCache1(i_CacheAddress)) {
            n_CacheReadData = caches1[block];
            n_CacheValidData = 1;
            lastSet[index] = 0;
            goto endUpdate;
        }

        if (checkCache2(i_CacheAddress)) {
            n_CacheReadData = caches2[block];
            n_CacheValidData = 1;
            lastSet[index] = 1;
            goto endUpdate;
        }

        fetchFromRam:
        fetchSet = !lastSet[index];
        n_FsbReadAddress = i_CacheAddress & 0xFFFFFE0;
        n_FsbReadRequest = 1;
        n_CacheValidData = 0;
        n_CacheFetching = 1;

    }

    endUpdate:
    return;

}



/**
 * @brief Output ports update function for data cache
 * 
 */
void InstructionCache::UpdatePorts(void)
{
    o_CacheReadData  = n_CacheReadData;
    o_CacheValidData = n_CacheValidData;
    o_CacheFetching  = n_CacheFetching;
    o_FsbReadAddress = n_FsbReadAddress;
    o_FsbReadRequest = n_FsbReadRequest;
}



/**
 * @brief Logging function for data cache
 * 
 */
void InstructionCache::log(void)
{
    Log::logSrc(" ICACHE  ", COLOR_BLUE);
    if (!n_CacheFetching) {

        if (i_CacheReadEnable) {

            Log::log("Read ");
            Log::logHex(i_CacheAddress, COLOR_MAGENTA, 8);
            Log::log(", ");
            if (checkCache1(i_CacheAddress)) {
                Log::log("[1: HIT]: ", COLOR_GREEN);
                Log::logHex(caches1[getBlock(i_CacheAddress)], COLOR_MAGENTA, 8);
            }
            if (checkCache2(i_CacheAddress)) {
                Log::log("[2: HIT]: ", COLOR_GREEN);
                Log::logHex(caches2[getBlock(i_CacheAddress)], COLOR_MAGENTA, 8);
            }
            Log::log("\n");

        } else {

            Log::log("Idle cycle\n");

        }

    } else {

        Log::log("Fetching\n");

    }
}