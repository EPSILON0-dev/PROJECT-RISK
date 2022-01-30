/**
 * @file dcache.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Data cache
 * @version 0.8
 * @date 2021-09-19
 * 
 * 
 * Each block of cache contains 32 bytes
 * 
 * Address is constructed like this:
 *   26    13   12        5   4         2   1        0
 *  [========] [===========] [===========] [==========]
 *     tag         index         block         byte
 * 
 * Possible errors:
 *  - read before write finishes
 *  - tripple index write
 * 
 * 
 */


#include "dcache.h"


extern bool memoryDebug;


/* State signals */


/* Pre-sequential combinational signals */
unsigned cpu_c_block {};
unsigned cpu_c_index {};
unsigned cpu_c_tag {};
unsigned fsb_c_block {};
unsigned fsb_c_index {};
unsigned fsb_c_tag {};

/* Sequential signals */
unsigned cpu_data_seq_1 {};
unsigned cpu_data_seq_2 {};
bool     cpu_valid_seq_1 {};
bool     cpu_valid_seq_2 {};
unsigned cpu_tag_seq_1 {};
unsigned cpu_tag_seq_2 {};
bool     cpu_last_set_seq {};
bool     fsb_fetch_set {};
bool     fetch_end {};

/* Post-sequential combinational signals */
bool     cpu_c_valid_1 {};
bool     cpu_c_valid_2 {};
bool     cpu_c_valid {};


/**
 * @brief Construct the Data Cache object
 * 
 */
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
    WAdrQueue = new unsigned[31];
    for (unsigned i = 0; i < 31; i++) WAdrQueue[i] = 0;
    queuePtr = 0;
}


static unsigned getBlock(unsigned a) { return (a >> 2) & 0x7; }
static unsigned getIndex(unsigned a) { return (a >> 5) & 0x1FF; }
static unsigned getTag(unsigned a) { return (a >> 13); }
bool DataCache::checkCache1(unsigned a) { return (tag1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]); }
bool DataCache::checkCache2(unsigned a) { return (tag2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]); }

/**
 * @brief Push write to the write queue
 * 
 * @param a Write address
 */
void DataCache::pushWrite(unsigned a) { 
    WAdrQueue[queuePtr++] = a & 0xFFFFFE0; 
}

/**
 * @brief Pull a write from write queue
 * 
 * @return Write address from queue
 */
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

/**
 * @brief Perform a single cycle of operation
 * 
 */
void DataCache::Update(void)
{

    /********************** PRE-SEQUENTIAL COMBINATIONAL *********************/
    cpu_c_block = getBlock(i_CAdr);
    cpu_c_index = getIndex(i_CAdr);
    cpu_c_tag   = getTag(i_CAdr);
    fsb_c_block = getBlock(i_FAdr);
    fsb_c_index = getIndex(i_FAdr);
    fsb_c_tag   = getTag(i_FAdr);


    /******************************* SEQUENTIAL ******************************/
    if (n_FRReq)  // Fetch initialization
    {
        n_CFetch = 1;
        if (i_FRAck) n_FRReq = 0;
        fsb_fetch_set = !cpu_last_set_seq;
    } 
    else if (n_CFetch)  // Fetch 
    {
        if (i_FWE) 
        {
            if (fsb_fetch_set)
            {
                cache2[fsb_c_block] = i_FWDat;
            }
            else
            {
                cache1[fsb_c_block] = i_FWDat;
            }
        }
        if (i_FLA)
        {
            n_CFetch = 0;
            fetch_end = 1;
            if (fsb_fetch_set)
            {
                tag2[fsb_c_index] = fsb_c_tag;
                valid2[fsb_c_index] = 1;
                lastSet[fsb_c_index] = 1;
                cpu_tag_seq_2 = fsb_c_tag;
                cpu_valid_seq_2 = 1;
            }
            else
            {
                tag1[fsb_c_index] = fsb_c_tag;
                valid1[fsb_c_index] = 1;
                lastSet[fsb_c_index] = 0;
                cpu_tag_seq_1 = fsb_c_tag;
                cpu_valid_seq_1 = 1;
            }
        }
    }
    else if (i_CRE || fetch_end)  // CPU read
    {
        fetch_end = 0;
        cpu_data_seq_1   = cache1[cpu_c_block];
        cpu_data_seq_2   = cache2[cpu_c_block];
        cpu_valid_seq_1  = valid1[cpu_c_index];
        cpu_valid_seq_2  = valid2[cpu_c_index];
        cpu_tag_seq_1    = tag1[cpu_c_index];
        cpu_tag_seq_2    = tag2[cpu_c_index];
        cpu_last_set_seq = lastSet[cpu_c_index];
    }


    /********************* POST-SEQUENTIAL COMBINATIONAL *********************/
    cpu_c_valid_1 = cpu_valid_seq_1 && (cpu_tag_seq_1 == cpu_c_tag);
    cpu_c_valid_2 = cpu_valid_seq_2 && (cpu_tag_seq_2 == cpu_c_tag);
    cpu_c_valid = cpu_c_valid_1 || cpu_c_valid_2;

    n_CRDat = (cpu_c_valid_1)? cpu_data_seq_1 : (cpu_c_valid_2)? cpu_data_seq_2 : 0;

    n_CVD = (cpu_c_valid && !fetch_end) || !i_CRE;

    n_FRAdr = i_CAdr & 0xFFFFFE0;
    n_FRReq = i_CRE && !cpu_c_valid && !n_CFetch;

}


/**
 * @brief Copy the data from internal outputs to output ports
 * 
 */
void DataCache::UpdatePorts(void)
{
    o_CRDat  = n_CRDat;
    o_CVD    = n_CVD;
    o_CFetch = n_CFetch;
    o_CWDone = 0; //n_CWDone;
    o_FRAdr  = n_FRAdr;
    o_FWAdr  = 0; //n_FWAdr;
    o_FWDat  = 0; //n_FWDat;
    o_FRReq  = n_FRReq;
    o_FWReq  = 0; //n_FWReq;
    o_FQFull = 0; //n_FQFull;
}


/**
 * @brief Log the activity
 * 
 */
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

        } else if (!!i_CWE) {

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


/**
 * @brief Log the activity
 * 
 */
void DataCache::logJson(void)
{

    Log::log("\"md\":\"");

    if (!n_CFetch) {

        if (i_CRE) {

            Log::log("Read ");
            Log::logHex(i_CAdr, 8);
            Log::log(", ");
            if (checkCache1(i_CAdr)) {
                Log::log("[1: HIT]: ");
                Log::logHex(cache1[getBlock(i_CAdr)], 8);
            }
            if (checkCache2(i_CAdr)) {
                Log::log("[2: HIT]: ");
                Log::logHex(cache2[getBlock(i_CAdr)], 8);
            }

        } else if (!!i_CWE) {

            Log::log("Write to ");
            Log::logHex(i_CAdr, 8);
            if (checkCache1(i_CAdr)) {
                Log::log(" cache ");
                Log::log("[1]: ");
                Log::logHex(i_CWDat, 8);
            }
            if (checkCache2(i_CAdr)) {
                Log::log(" cache ");
                Log::log("[2]: ");
                Log::logHex(i_CWDat, 8);
            }

        } else {

            Log::log("Idle cycle");

        }

    } else {

        Log::log("Fetching");

    }

    if (queuePtr) {
      Log::log(" [Q:");
      Log::logDec(queuePtr);
      Log::log("]");
    }
    Log::log("\",");
    
}

/*
unsigned block = getBlock(i_CAdr);
    unsigned index = getIndex(i_CAdr);

    if (i_FRAck) { n_FRReq = 0; }  // Turn off read request on ACK

    if (i_FWAck) { n_FWReq = 0; }  // Turn off write request on ACK

    if (i_FRE) {  // Handle writing to RAM

        if (checkCache1(i_FAdr)) {
            n_FWDat = cache1[getBlock(i_FAdr)];
            if (memoryDebug) {
                Log::logSrc(" DCACHE WR ");
                Log::log("Writing ");
                Log::logHex(n_FWDat, COLOR_MAGENTA, 8);
                Log::log(" to ");
                Log::logHex(i_FAdr, COLOR_MAGENTA, 8);
                Log::log(" from array 1\n");
            }
        } else if (checkCache2(i_FAdr)) {
            n_FWDat = cache2[getBlock(i_FAdr)];
            if (memoryDebug) {
                Log::logSrc(" DCACHE WR ");
                Log::log("Writing ");
                Log::logHex(n_FWDat, COLOR_MAGENTA, 8);
                Log::log(" to ");
                Log::logHex(i_FAdr, COLOR_MAGENTA, 8);
                Log::log(" from array 2\n");
            }
        } else {
            n_FWDat = 0;
        }

        if (i_FLA) {
            if (!rewrite) {
                pullWrite();
            } else {
                rewrite = 0;
            }
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
            if (memoryDebug) {
                Log::logSrc(" DCACHE RD ");
                Log::log("Fetching ");
                Log::logHex(cache2[getBlock(i_FAdr)], COLOR_MAGENTA, 8);
                Log::log(" from ");
                Log::logHex(i_FAdr, COLOR_MAGENTA, 8);
                Log::log(" to array 2\n");
            }
        } else {
            cache1[getBlock(i_FAdr)] = i_FWDat;
            if (memoryDebug) {
                Log::logSrc(" DCACHE RD ");
                Log::log("Fetching ");
                Log::logHex(cache1[getBlock(i_FAdr)], COLOR_MAGENTA, 8);
                Log::log(" from ");
                Log::logHex(i_FAdr, COLOR_MAGENTA, 8);
                Log::log(" to array 1\n");
            }
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

    if (i_CRE || !!i_CWE) { Adr = i_CAdr; }

    if (!n_CFetch && !!i_CWE) {  // Handle writes

        if (!(checkCache1(Adr) || checkCache2(Adr))) { goto fetchFromRam; }

        if (checkCache1(Adr)) {
            unsigned char* blockBase = (unsigned char*)&cache1[block];
            if (i_CWE & 0x1) blockBase[0] = (i_CWDat)       & 0xFF;
            if (i_CWE & 0x2) blockBase[1] = (i_CWDat >>  8) & 0xFF;
            if (i_CWE & 0x4) blockBase[2] = (i_CWDat >> 16) & 0xFF;
            if (i_CWE & 0x8) blockBase[3] = (i_CWDat >> 24) & 0xFF;

            lastSet[index] = 0;
            n_CVD = 1;

            if (!queue1[index]) {
                n_FWReq = 1;
                if (!n_FQFull) {
                    pushWrite(Adr);
                    queue1[index] = 1;
                    n_CWDone = 1;
                } else {
                    n_CWDone = 0;
                }
            } else {
                rewrite = 1;
            }

            goto endUpdate;
        }

        if (checkCache2(Adr)) {
            unsigned char* blockBase = (unsigned char*)&cache2[block];
            if (i_CWE & 0x1) blockBase[0] = (i_CWDat)       & 0xFF;
            if (i_CWE & 0x2) blockBase[1] = (i_CWDat >>  8) & 0xFF;
            if (i_CWE & 0x4) blockBase[2] = (i_CWDat >> 16) & 0xFF;
            if (i_CWE & 0x8) blockBase[3] = (i_CWDat >> 24) & 0xFF;

            lastSet[index] = 1;
            n_CVD = 1;

            if (!queue2[index]) {
                n_FWReq = 1;
                if (!n_FQFull) {
                    pushWrite(Adr);
                    queue2[index] = 1;
                    n_CWDone = 1;
                } else {
                    n_CWDone = 0;
                }
            } else {
                rewrite = 1;
            }

            goto endUpdate;
        }

    }

    if (!n_CFetch) {  // Handle reads

        if (!(checkCache1(Adr) || checkCache2(Adr))) {
            goto fetchFromRam;
        }

        if (checkCache1(Adr)) {
            n_CRDat = cache1[getBlock(Adr)];
            n_CVD = 1;
            lastSet[index] = 0;
            goto endUpdate;
        }

        if (checkCache2(Adr)) {
            n_CRDat = cache2[getBlock(Adr)];
            n_CVD = 1;
            lastSet[index] = 1;
            goto endUpdate;
        }

        fetchFromRam:
        fetchSet = !lastSet[getIndex(Adr)];
        n_FRAdr = Adr & 0xFFFFFE0;
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
*/
