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
 *   26    13   12        5   4         2   1        0
 *  [========] [===========] [===========] [==========]
 *     tag         index         block         byte
 *
 */


#include "icache.h"


/* State signals */
static bool     fetch_end {};

/* Pre-sequential combinational signals */
static unsigned cpu_c_block {};
static unsigned cpu_c_index {};
static unsigned cpu_c_tag {};
static unsigned fsb_c_block {};
static unsigned fsb_c_index {};
static unsigned fsb_c_tag {};

/* Sequential signals */
static unsigned cpu_data_seq_1 {};
static unsigned cpu_data_seq_2 {};
static bool     cpu_valid_seq_1 {};
static bool     cpu_valid_seq_2 {};
static unsigned cpu_tag_seq_1 {};
static unsigned cpu_tag_seq_2 {};
static bool     cpu_last_set_seq {};
static bool     fsb_fetch_set {};
static unsigned read_index {};

/* Post-sequential combinational signals */
static bool     cpu_c_valid_1 {};
static bool     cpu_c_valid_2 {};
static bool     cpu_c_valid {};
static bool     c_update_set {};
static bool     c_new_set {};


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
static unsigned getIndex(unsigned a) { return (a >> 5) & 0x0FF; }
static unsigned getTag(unsigned a) { return (a >> 13); }
bool InstructionCache::checkCache1(unsigned a) { return (tag1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]); }
bool InstructionCache::checkCache2(unsigned a) { return (tag2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]); }


/**
 * @brief Perform a single cycle of operation
 *
 */
void InstructionCache::Update(void)
{

    /********************** PRE-SEQUENTIAL COMBINATIONAL **********************/
    cpu_c_block = getBlock(i_CAdr);
    cpu_c_index = getIndex(i_CAdr);
    cpu_c_tag   = getTag(i_CAdr);
    fsb_c_block = getBlock(i_FAdr);
    fsb_c_index = getIndex(i_FAdr);
    fsb_c_tag   = getTag(i_FAdr);


    /******************************* SEQUENTIAL *******************************/
    if (c_update_set) {  // Update lastSet
        lastSet[read_index] = c_new_set;
    }
    read_index = cpu_c_index;

    if (n_FRReq)  // Fetch initialization
    {
        if (i_FRAck) n_CFetch = 1;
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
    else  // CPU read
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


    /********************* POST-SEQUENTIAL COMBINATIONAL **********************/
    cpu_c_valid_1 = cpu_valid_seq_1 && (cpu_tag_seq_1 == cpu_c_tag);
    cpu_c_valid_2 = cpu_valid_seq_2 && (cpu_tag_seq_2 == cpu_c_tag);
    cpu_c_valid = cpu_c_valid_1 || cpu_c_valid_2;

    n_CRDat = (
        (cpu_c_valid_1)? cpu_data_seq_1 :
        (cpu_c_valid_2)? cpu_data_seq_2 :
        0
    );

    n_CVD = (cpu_c_valid && !fetch_end);

    n_FRAdr = i_CAdr & 0xFFFFFE0;
    n_FRReq = !cpu_c_valid && !n_CFetch;

    c_update_set = cpu_c_valid;
    c_new_set = cpu_c_valid_2;
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


/**
 * @brief Log the activity
 *
 */
void InstructionCache::logJson(void)
{
    Log::log("\"mi\":\"");

    if (n_CFetch) { Log::log("Fetching\","); return; }

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
        Log::log("\",");
        return;
    }

    Log::log("Idle cycle\",");

}
