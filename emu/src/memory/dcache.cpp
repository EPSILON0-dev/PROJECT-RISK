/**
 * @file dcache.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Data cache
 * @version 0.8
 * @date 2021-09-19
 *
 *
 * This is the part of code that you don't touch and it just works
 *   Except for the fact it does not
 *
 * Address is constructed like this:
 *   26    13   12        5   4         2   1        0
 *  [========] [===========] [===========] [==========]
 *     tag         index         block         byte
 *
 *
 */


#include "dcache.h"


extern bool memoryDebug;
typedef unsigned char byte;


/* State signals */
static bool     fetch_end {};
static bool     write_lock {};
static bool     write_end {};

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
static unsigned wr_data {};
static unsigned wr_addr {};
static unsigned wr_en {};
static bool     wb_set {};
static unsigned wb_index {};
static bool     wb_wr {};
static bool     wb_wr_en {};

/* Post-sequential combinational signals */
static bool     cpu_c_valid_1 {};
static bool     cpu_c_valid_2 {};
static bool     cpu_c_valid {};


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
}


static unsigned getBlock(unsigned a) { return (a >> 2) & 0xFFF; }
static unsigned getIndex(unsigned a) { return (a >> 5) & 0x1FF; }
static unsigned getTag(unsigned a) { return (a >> 13); }
bool DataCache::checkCache1(unsigned a) {
    return (tag1[getIndex(a)] == getTag(a) && valid1[getIndex(a)]);
}
bool DataCache::checkCache2(unsigned a) {
    return (tag2[getIndex(a)] == getTag(a) && valid2[getIndex(a)]);
}

/**
 * @brief Perform a single cycle of operation
 *
 */
void DataCache::Update(void)
{

    /********************** PRE-SEQUENTIAL COMBINATIONAL **********************/
    cpu_c_block = getBlock(i_CAdr);
    cpu_c_index = getIndex(i_CAdr);
    cpu_c_tag   = getTag(i_CAdr);
    fsb_c_block = getBlock(i_FAdr);
    fsb_c_index = getIndex(i_FAdr);
    fsb_c_tag   = getTag(i_FAdr);


    /******************************* SEQUENTIAL *******************************/

    if (wr_en)  // CPU write
    {
        unsigned wr_base = getBlock(wr_addr) << 2;
        if (cpu_c_valid_1) {
            if (wr_en & 0x1) ((byte*)cache1)[wr_base+0] = ((byte*)&wr_data)[0];
            if (wr_en & 0x2) ((byte*)cache1)[wr_base+1] = ((byte*)&wr_data)[1];
            if (wr_en & 0x4) ((byte*)cache1)[wr_base+2] = ((byte*)&wr_data)[2];
            if (wr_en & 0x8) ((byte*)cache1)[wr_base+3] = ((byte*)&wr_data)[3];
            lastSet[getIndex(wr_addr)] = 0;
            wb_wr_en = 1;
            wb_index = wr_addr;
            wb_set = 0;
        }
        if (cpu_c_valid_2) {
            if (wr_en & 0x1) ((byte*)cache2)[wr_base+0] = ((byte*)&wr_data)[0];
            if (wr_en & 0x2) ((byte*)cache2)[wr_base+1] = ((byte*)&wr_data)[1];
            if (wr_en & 0x4) ((byte*)cache2)[wr_base+2] = ((byte*)&wr_data)[2];
            if (wr_en & 0x8) ((byte*)cache2)[wr_base+3] = ((byte*)&wr_data)[3];
            lastSet[getIndex(wr_addr)] = 1;
            wb_wr_en = 1;
            wb_index = wr_addr;
            wb_set = 1;
        }
    }

    if (write_end)  // Clear write_end
    {
        write_end = 0;
    }

    if (wb_wr_en)  // Write back initialization
    {
        write_lock = 1;
        if (i_FWAck) {
            wb_wr = 1;
            wb_wr_en = 0;
        }
    }

    else if (wb_wr)  // Write back
    {
        if (i_FRE) {
            if (wb_set) {
                n_FWDat = cache2[fsb_c_block];
            } else {
                n_FWDat = cache1[fsb_c_block];
            }
        }

        if (i_FLA) {
            lastSet[fsb_c_index] = wb_set;
            wb_wr = 0;
            fetch_end = 1;
            write_lock = 0;
            write_end = 1;
        }
    }


    if (n_FRReq)  // Fetch initialization
    {
        if (i_FRAck) n_CFetch = 1;
        fsb_fetch_set = !cpu_last_set_seq;
    }

    else if (n_CFetch)  // Fetch
    {
        if (i_FWE) {
            if (fsb_fetch_set) {
                cache2[fsb_c_block] = i_FWDat;
            } else {
                cache1[fsb_c_block] = i_FWDat;
            }
        }

        if (i_FLA) {
            n_CFetch = 0;
            fetch_end = 1;
            if (fsb_fetch_set) {
                tag2[fsb_c_index] = fsb_c_tag;
                valid2[fsb_c_index] = 1;
                lastSet[fsb_c_index] = 1;
                cpu_tag_seq_2 = fsb_c_tag;
                cpu_valid_seq_2 = 1;
            } else {
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

    // Store write parameters
    wr_addr = i_CAdr;
    wr_data = i_CWDat;
    wr_en = (!!wr_en || write_lock) ? 0 : i_CWE;


    /********************* POST-SEQUENTIAL COMBINATIONAL **********************/
    cpu_c_valid_1 = cpu_valid_seq_1 && (cpu_tag_seq_1 == cpu_c_tag);
    cpu_c_valid_2 = cpu_valid_seq_2 && (cpu_tag_seq_2 == cpu_c_tag);
    cpu_c_valid = cpu_c_valid_1 || cpu_c_valid_2;

    n_CRDat = (
        (cpu_c_valid_1)? cpu_data_seq_1 :
        (cpu_c_valid_2)? cpu_data_seq_2 :
        0
    );

    bool no_acc = !(i_CRE || !!i_CWE);
    bool fetch = (!cpu_c_valid || n_CFetch || fetch_end);
    bool write = (write_lock && !write_end);
    n_CVD = !(fetch || write) || no_acc;

    // std::cout << n_CVD << write_lock << write_end;
    // std::cout << wr_en << wb_wr << wb_wr_en;

    n_FRAdr = ((wb_wr || wb_wr_en)? wr_addr : i_CAdr) & 0xFFFFFE0;
    n_FRReq = (i_CRE || !!i_CWE) && !cpu_c_valid && !n_CFetch;
    n_FWReq = wb_wr_en && !wb_wr;

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
    o_FRAdr  = n_FRAdr;
    o_FWAdr  = wb_index;
    o_FWDat  = n_FWDat;
    o_FRReq  = n_FRReq;
    o_FWReq  = n_FWReq;
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

    Log::log("\",");

}
