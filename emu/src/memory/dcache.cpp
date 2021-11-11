/**
 * DATA CACHE
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
 * 
 * IMPORTANT TODO:
 *  improve the system of queueing, when both sets are queued and request to fetch
 *  another block (with the same index) data can be lost
 * 
 */

#include "../common/config.h"
#include "../common/log.h"
#include "fsb.h"
#include "dcache.h"



/**
 * @brief Constructor
 * 
 */
DataCache::DataCache(void)
{
    caches1 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) caches1[i] = 0;
    tags1 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tags1[i] = 0;
    valid1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid1[i] = 0;
    queued1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) queued1[i] = 0;
    caches2 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) caches2[i] = 0;
    tags2 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tags2[i] = 0;
    valid2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid2[i] = 0;
    queued2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) queued1[i] = 0;
    lastSet = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) lastSet[i] = 0;
    writeAddressQueue = new unsigned[32];
    for (unsigned i = 0; i < 32; i++) writeAddressQueue[i] = 0;
    queuePointer = 0;
    fetchSet = 0;

    i_CacheAddress = 0;
    i_CacheWriteData = 0;
    i_CacheWriteEnable = 0;
    i_CacheReadEnable = 0;
    i_FsbAddress = 0;
    i_FsbWriteData = 0;
    i_FsbWriteEnable = 0;
    i_FsbReadEnable = 0;
    i_FsbLastAccess = 0;
    i_FsbReadAck = 0;
    i_FsbWriteAck = 0;

    n_CacheReadData = 0;
    n_CacheValidData = 1;
    n_CacheFetching = 0;
    n_FsbReadAddress = 0;
    n_FsbReadRequest = 0;
    n_FsbWriteRequest = 0;
    n_FsbQueueFull = 0;

    o_CacheReadData = 0;
    o_CacheValidData = 1;
    o_CacheFetching = 0;
    o_FsbReadAddress = 0;
    o_FsbReadRequest = 0;
    o_FsbWriteRequest = 0;
    o_FsbQueueFull = 0;

    readAddress = 0;
}



/**
 * @brief Destructor
 * 
 */
DataCache::~DataCache(void)
{
    delete[] caches1;
    delete[] caches2;
    delete[] tags1;
    delete[] tags2;
    delete[] valid1;
    delete[] valid2;
    delete[] lastSet;
    delete[] writeAddressQueue;
}



unsigned DataCache::getBlock(unsigned a)
{
    return (a >> 2) & 0x7;
}

unsigned DataCache::getIndex(unsigned a)
{
    return (a >> 5) & 0xFF;
}

unsigned DataCache::getTag(unsigned a)
{
    return (a >> 14);
}

bool DataCache::checkCache1(unsigned a)
{
    return (tags1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]);
}

bool DataCache::checkCache2(unsigned a)
{
    return (tags2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]);
}

void DataCache::pushWrite(unsigned a)
{
    writeAddressQueue[queuePointer++] = a & 0xFFFFFE0;
}

unsigned DataCache::pullWrite(void)
{
    unsigned a = writeAddressQueue[0];
    for (unsigned i = 0; i < 31; i++)
        writeAddressQueue[i] = writeAddressQueue[i+1];
    writeAddressQueue[31] = 0;
    if (queuePointer > 0)
        queuePointer--;
    return a;
}



/**
 * @brief Update function for data cache
 * 
 */
void DataCache::Update(void)
{

    unsigned block = getBlock(i_CacheAddress);
    unsigned index = getIndex(i_CacheAddress);

    if (i_FsbReadAck) {  // Turn off read request on ACK
        n_FsbReadRequest = 0;
    }

    if (i_FsbWriteAck) {  // Turn off write request on 
        n_FsbWriteRequest = 0;
    }

    if (i_FsbReadEnable) {  // Handle writing to RAM

        if (checkCache1(i_FsbAddress)) {
            n_FsbWriteData = caches1[getBlock(i_FsbAddress)];
        } else if (checkCache2(i_FsbAddress)) {
            n_FsbWriteData = caches2[getBlock(i_FsbAddress)];
        } else {
            n_FsbWriteData = 0x55AA55AA;
        }

        if (i_FsbLastAccess) {
            pullWrite();
            if (checkCache1(i_FsbAddress)) {
                queued1[getIndex(i_FsbAddress)] = 0;
            } else {
                queued2[getIndex(i_FsbAddress)] = 0;
            }
        }

    }

    if (n_CacheFetching && i_FsbWriteEnable) {  // Handle fetching from RAM
        
        if (fetchSet) {
            caches2[getBlock(i_FsbAddress)] = i_FsbWriteData;
        } else {
            caches1[getBlock(i_FsbAddress)] = i_FsbWriteData;
        }
    
        if (i_FsbLastAccess) {
            n_CacheFetching = 0;
            if (fetchSet) {
                tags2[getIndex(i_FsbAddress)] = getTag(i_FsbAddress);
                valid2[getIndex(i_FsbAddress)] = 1;
                lastSet[getIndex(i_FsbAddress)] = 1;
            } else {
                tags1[getIndex(i_FsbAddress)] = getTag(i_FsbAddress);
                valid1[getIndex(i_FsbAddress)] = 1;
                lastSet[getIndex(i_FsbAddress)] = 0;
            }

        }

        goto endUpdate;

    }

    if (i_CacheReadEnable) {
        readAddress = i_CacheAddress;
    }

    if (!n_CacheFetching && i_CacheWriteEnable) {  // Handle writes

        if (!(checkCache1(readAddress) || checkCache2(readAddress))) {
            goto fetchFromRam;
        }

        if (checkCache1(readAddress)) {
            lastSet[index] = 0;
            caches1[block] = i_CacheWriteData;
            
            if (!queued1[index]) {
                n_FsbWriteRequest = 1;
                if (!n_FsbQueueFull) {
                    pushWrite(readAddress);
                    queued1[index] = 1;
                    n_CacheWriteDone = 1;
                } else {
                    n_CacheWriteDone = 0;
                }
            }
            goto endUpdate;
        }

        if (checkCache2(readAddress)) {
            lastSet[index] = 1;
            caches2[block] = i_CacheWriteData;
            if (!queued2[index]) {
                n_FsbWriteRequest = 1;
                if (!n_FsbQueueFull) {
                    pushWrite(readAddress);
                    queued2[index] = 1;
                    n_CacheWriteDone = 1;
                } else {
                    n_CacheWriteDone = 0;
                }
            }
            goto endUpdate;
        }

    }

    if (!n_CacheFetching) {  // Handle reads

        if (!(checkCache1(readAddress) || checkCache2(readAddress))) {
            goto fetchFromRam;
        }

        if (checkCache1(readAddress)) {
            n_CacheReadData = caches1[getBlock(readAddress)];
            n_CacheValidData = 1;
            lastSet[index] = 0;
            goto endUpdate;
        }

        if (checkCache2(readAddress)) {
            n_CacheReadData = caches2[getBlock(readAddress)];
            n_CacheValidData = 1;
            lastSet[index] = 1;
            goto endUpdate;
        }

        fetchFromRam:
        fetchSet = !lastSet[getIndex(readAddress)];
        n_FsbReadAddress = readAddress & 0xFFFFFE0;
        n_FsbReadRequest = 1;
        n_CacheValidData = 0;
        n_CacheFetching = 1;
        goto endUpdate;

    }

    endUpdate:
    if (queuePointer) {  // Turn on or off write request based on queue state
        n_FsbWriteAddress = writeAddressQueue[0];
        n_FsbQueueFull = (queuePointer == 32);
        if (queuePointer > 1)
            n_FsbWriteRequest = 1;
    }
    return;

}



/**
 * @brief Output ports update function for data cache
 * 
 */
void DataCache::UpdatePorts(void)
{
    o_CacheReadData   = n_CacheReadData;
    o_CacheValidData  = n_CacheValidData;
    o_CacheFetching   = n_CacheFetching;
    o_CacheWriteDone  = n_CacheWriteDone;
    o_FsbReadAddress  = n_FsbReadAddress;
    o_FsbWriteAddress = n_FsbWriteAddress;
    o_FsbWriteData    = n_FsbWriteData;
    o_FsbReadRequest  = n_FsbReadRequest;
    o_FsbWriteRequest = n_FsbWriteRequest;
    o_FsbQueueFull    = n_FsbQueueFull;
}



/**
 * @brief Logging function for data cache
 * 
 */
void DataCache::log(void)
{

    Log::logSrc(" DCACHE  ", COLOR_BLUE);

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

        } else if (i_CacheWriteEnable) {

            Log::log("Write to ");
            Log::logHex(i_CacheAddress, COLOR_MAGENTA, 8);
            if (checkCache1(i_CacheAddress)) {
                Log::log(" cache ");
                Log::log("[1]: ", COLOR_GREEN);
                Log::logHex(i_CacheWriteData, COLOR_MAGENTA, 8);
            }
            if (checkCache2(i_CacheAddress)) {
                Log::log(" cache ");
                Log::log("[2]: ", COLOR_GREEN);
                Log::logHex(i_CacheWriteData, COLOR_MAGENTA, 8);
            }

        } else {

            Log::log("Idle cycle");

        }

    } else {

        Log::log("Fetching");

    }

    if (queuePointer) {
      Log::log(" [Q:", COLOR_CYAN);
      Log::logDec(queuePointer, COLOR_CYAN);
      Log::log("]", COLOR_CYAN);
    }

    Log::log("\n");
    
}
