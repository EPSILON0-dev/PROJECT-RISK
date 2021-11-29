/**
 * @file icache.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Instruction cache
 * @version 0.7
 * @date 2021-09-19
 * 
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
 * @brief Construct the Instruction Cache object
 * 
 */
InstructionCache::InstructionCache(void)
{
    cache1 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) cache1[i] = 0;
    tag1 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tag1[i] = 0;
    valid1 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid1[i] = 0;
    cache2 = new unsigned[2048];
    for (unsigned i = 0; i < 2048; i++) cache2[i] = 0;
    tag2 = new unsigned short[256];
    for (unsigned i = 0; i < 256; i++) tag2[i] = 0;
    valid2 = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) valid2[i] = 0;
    lastSet = new unsigned char[256];
    for (unsigned i = 0; i < 256; i++) lastSet[i] = 0;
}


static unsigned getBlock(unsigned a) { return (a >> 2) & 0x7FF; }
static unsigned getIndex(unsigned a) { return (a >> 5) & 0xFF; }
static unsigned getTag(unsigned a) { return (a >> 14); }
bool InstructionCache::checkCache1(unsigned a) { return (tag1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]); }
bool InstructionCache::checkCache2(unsigned a) { return (tag2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]); }
 

/**
 * @brief Perform a single cycle of operation
 * 
 */
void InstructionCache::Update(void)
{

    if (i_FRAck) { n_FRReq = 0; }  // Stop requesting on ACK

    if (n_CFetch && i_FWE) {  // Handle FSB writes

        unsigned fsb_block = getBlock(i_FAdr);
        unsigned fsb_index = getIndex(i_FAdr);
        unsigned fsb_tag   = getTag(i_FAdr);
        
        if (fetchSet) {
            cache2[fsb_block] = i_FWDat;
            tag2[fsb_index] = fsb_tag;
            valid2[fsb_index] = 1;
            lastSet[fsb_index] = 1;
        } else {
            cache1[fsb_block] = i_FWDat;
            tag1[fsb_index] = fsb_tag;
            valid1[fsb_index] = 1;
            lastSet[fsb_index] = 0;
        }
    
        if (i_FLA) { n_CFetch = 0; }  // On last access exit fetching state
 
        goto endUpdate;

    }

    if (i_CRE&& !n_CFetch) {  // Handle the CPU reads

        unsigned cpu_block = getBlock(i_CAdr);
        unsigned cpu_index = getIndex(i_CAdr);

        // If address missed fetch from RAM
        if (!(checkCache1(i_CAdr) || checkCache2(i_CAdr))) { goto fetchFromRam; }

        if (checkCache1(i_CAdr)) {
            n_CRDat = cache1[cpu_block];
            n_CVD = 1;
            lastSet[cpu_index] = 0;
            goto endUpdate;
        }

        if (checkCache2(i_CAdr)) {
            n_CRDat = cache2[cpu_block];
            n_CVD = 1;
            lastSet[cpu_index] = 1;
            goto endUpdate;
        }

        fetchFromRam:
        fetchSet = !lastSet[cpu_index];
        n_FRAdr = i_CAdr & 0xFFFFFE0;
        n_FRReq = 1;
        n_CVD = 0;
        n_CFetch = 1;

    }

    endUpdate:
    n_CVD |= !i_CRE && !n_CFetch;
    return;

}


/**
 * @brief Copy the data from internal outputs to output ports
 * 
 */
void InstructionCache::UpdatePorts(void)
{
    o_CRDat  = n_CRDat;
    o_CVD    = n_CVD;
    o_CFetch = n_CFetch;
    o_FRAdr  = n_FRAdr;
    o_FRReq  = n_FRReq;
}


/**
 * @brief Log the activity
 * 
 */
void InstructionCache::log(void)
{
    Log::logSrc(" ICACHE  ", COLOR_BLUE);

    if (n_CFetch) { Log::log("Fetching\n"); return; }

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
        Log::log("\n");
        return;
    } 

    Log::log("Idle cycle\n");

}