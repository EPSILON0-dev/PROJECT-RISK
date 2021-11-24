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


DataCache::DataCache(void)
{
    cache1 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) cache1[i] = 0;
    tag1 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tag1[i] = 0;
    valid1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid1[i] = 0;
    queue1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) queue1[i] = 0;
    cache2 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) cache2[i] = 0;
    tag2 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tag2[i] = 0;
    valid2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid2[i] = 0;
    queue2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) queue2[i] = 0;
    lastSet = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) lastSet[i] = 0;
    WAdrQueue = new unsigned[32];
    for (unsigned i = 0; i < 32; i++) WAdrQueue[i] = 0;
    queuePtr = 0;
    fetchSet = 0;
}


static unsigned getBlock(unsigned a) { return (a >> 2) & 0x7; }
static unsigned getIndex(unsigned a) { return (a >> 5) & 0xFF; }
static unsigned getTag(unsigned a) { return (a >> 14); }
bool DataCache::checkCache1(unsigned a) { return (tag1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]); }
bool DataCache::checkCache2(unsigned a) { return (tag2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]); }
void DataCache::pushWrite(unsigned a) { WAdrQueue[queuePtr++] = a & 0xFFFFFE0; }
unsigned DataCache::pullWrite(void)
{
    unsigned a = WAdrQueue[0];
    for (unsigned i = 0; i < 31; i++)
        WAdrQueue[i] = WAdrQueue[i+1];
    WAdrQueue[31] = 0;
    if (queuePtr > 0)
        queuePtr--;
    return a;
}


void DataCache::Update(void)  // TODO: Rewrite/make work
{

    unsigned block = getBlock(i_CAdr);
    unsigned index = getIndex(i_CAdr);

    if (i_FRAck) { n_FRReq = 0; }  // Turn off read request on ACK

    if (i_FWAck) { n_FWReq = 0; }  // Turn off write request on ACK

    if (i_FRE) {  // Handle writing to RAM

        if (checkCache1(i_FAdr)) {
            i_FWDat = cache1[getBlock(i_FAdr)];
        } else if (checkCache2(i_FAdr)) {
            i_FWDat = cache2[getBlock(i_FAdr)];
        } else {
            i_FWDat = 0x55AA55AA;
        }

        if (i_FLA) {
            pullWrite();
            if (checkCache1(i_FAdr)) {
                queue1[getIndex(i_FAdr)] = 0;
            } else {
                queue2[getIndex(i_FAdr)] = 0;
            }
        }

    }

    if (n_CFetch && i_FWE) {  // Handle fetching from RAM
        
        if (fetchSet) {
            cache2[getBlock(i_FAdr)] = i_FWDat;
        } else {
            cache1[getBlock(i_FAdr)] = i_FWDat;
        }
    
        if (i_FLA) {
            n_CFetch = 0;
            if (fetchSet) {
                tag2[getIndex(i_FAdr)] = getTag(i_FAdr);
                valid2[getIndex(i_FAdr)] = 1;
                lastSet[getIndex(i_FAdr)] = 1;
            } else {
                tag1[getIndex(i_FAdr)] = getTag(i_FAdr);
                valid1[getIndex(i_FAdr)] = 1;
                lastSet[getIndex(i_FAdr)] = 0;
            }
        }

        goto endUpdate;

    }

    if (i_CRE) { RAdr = i_CAdr; }

    if (!n_CFetch && i_CWE) {  // Handle writes

        if (!(checkCache1(RAdr) || checkCache2(RAdr))) {
            goto fetchFromRam;
        }

        if (checkCache1(RAdr)) {
            lastSet[index] = 0;
            cache1[block] = i_CWDat;
            
            if (!queue1[index]) {
                n_FWReq = 1;
                if (!n_FQFull) {
                    pushWrite(RAdr);
                    queue1[index] = 1;
                    n_CWDone = 1;
                } else {
                    n_CWDone = 0;
                }
            }
            goto endUpdate;
        }

        if (checkCache2(RAdr)) {
            lastSet[index] = 1;
            cache2[block] = i_CWDat;
            if (!queue2[index]) {
                n_FWReq = 1;
                if (!n_FQFull) {
                    pushWrite(RAdr);
                    queue2[index] = 1;
                    n_CWDone = 1;
                } else {
                    n_CWDone = 0;
                }
            }
            goto endUpdate;
        }

    }

    if (!n_CFetch) {  // Handle reads

        if (!(checkCache1(RAdr) || checkCache2(RAdr))) {
            goto fetchFromRam;
        }

        if (checkCache1(RAdr)) {
            n_CRDat = cache1[getBlock(RAdr)];
            n_CVD = 1;
            lastSet[index] = 0;
            goto endUpdate;
        }

        if (checkCache2(RAdr)) {
            n_CRDat = cache2[getBlock(RAdr)];
            n_CVD = 1;
            lastSet[index] = 1;
            goto endUpdate;
        }

        fetchFromRam:
        fetchSet = !lastSet[getIndex(RAdr)];
        n_FRAdr = RAdr & 0xFFFFFE0;
        n_FRReq = 1;
        n_CVD = 0;
        n_CFetch = 1;
        goto endUpdate;

    }

    endUpdate:
    if (queuePtr) {  // Turn on or off write request based on queue state
        n_FWAdr = WAdrQueue[0];
        n_FQFull = (queuePtr == 32);
        if (queuePtr > 1)
            n_FWReq = 1;
    }
    return;

}


void DataCache::UpdatePorts(void)
{
    o_CRDat  = n_CRDat;
    o_CVD    = n_CVD;
    o_CFetch = n_CFetch;
    o_CWDone = n_CWDone;
    o_FRAdr  = n_FRAdr;
    o_FWAdr  = n_FWAdr;
    o_FWDat  = n_FWDat;
    o_FRReq  = n_FRReq;
    o_FWReq  = n_FWReq;
    o_FQFull = n_FQFull;
}


void DataCache::log(void)
{

    Log::logSrc(" DCACHE  ", COLOR_BLUE);

    if (!n_CFetch) {

        if (i_CRE) {

            Log::log("Read ");
            Log::logHex(i_CAdr, COLOR_MAGENTA, 8);
            Log::log(", ");
            if (checkCache1(i_CAdr)) {
                Log::log("[1: HIT]: ", COLOR_GREEN);
                Log::logHex(cache1[getBlock(i_CAdr)], COLOR_MAGENTA, 8);
            }
            if (checkCache2(i_CAdr)) {
                Log::log("[2: HIT]: ", COLOR_GREEN);
                Log::logHex(cache2[getBlock(i_CAdr)], COLOR_MAGENTA, 8);
            }

        } else if (i_CWE) {

            Log::log("Write to ");
            Log::logHex(i_CAdr, COLOR_MAGENTA, 8);
            if (checkCache1(i_CAdr)) {
                Log::log(" cache ");
                Log::log("[1]: ", COLOR_GREEN);
                Log::logHex(i_CWDat, COLOR_MAGENTA, 8);
            }
            if (checkCache2(i_CAdr)) {
                Log::log(" cache ");
                Log::log("[2]: ", COLOR_GREEN);
                Log::logHex(i_CWDat, COLOR_MAGENTA, 8);
            }

        } else {

            Log::log("Idle cycle");

        }

    } else {

        Log::log("Fetching");

    }

    if (queuePtr) {
      Log::log(" [Q:", COLOR_CYAN);
      Log::logDec(queuePtr, COLOR_CYAN);
      Log::log("]", COLOR_CYAN);
    }

    Log::log("\n");
    
}