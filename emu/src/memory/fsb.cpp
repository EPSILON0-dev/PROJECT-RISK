/**
 * @file fsb.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Front Side Bus
 * @version 0.7
 * @date 2021-09-19
 *
 *
 * In the final system 3 read callers and 1 write caller are expected
 * On chip access will be performed ommiting the cache and thus the FSB
 *
 * Final priority will be:
 *  1. Write queue when full
 *  2. VGA controller
 *  3. CPU D cache
 *  4. CPU I cache
 *  5. Write queue when not full
 *
 */


#include "fsb.h"


static InstructionCache* iCache;
static DataCache* dCache;
static MainRam* ddr;


FrontSideBus::FrontSideBus(void)
{
    reqAdr = 0;
    req = cNone;
}


/**
 * @brief Load the memory class pointers
 *
 * @param instructionCache Instruction Cache pointer
 * @param dataCache Data Cache pointer
 * @param mainRam Main LPDDR RAM pointer
 */
void FrontSideBus::loadPointers(void* instructionCache, void* dataCache, void* mainRam)
{
    iCache = (InstructionCache*)instructionCache;
    dCache = (DataCache*)dataCache;
    ddr = (MainRam*)mainRam;
}


/**
 * @brief Perform a single cycle of operation
 *
 */
void FrontSideBus::Update(void)
{

    if (req) {  // Continue currently serviced request

        request:

        if (dCache) {
            if (req == cDCache) {
                dCache->i_FAdr = ddr->o_CAdr;
                dCache->i_FWDat = ddr->o_CWDat;
                dCache->i_FWE = ddr->o_CWE;
                dCache->i_FRE = 0;
                dCache->i_FLA = ddr->o_CLA;
                dCache->i_FRAck = ddr->o_RAck;
                dCache->i_FWAck = 0;
                ddr->i_RRq = dCache->o_FRReq;
            } else if (req == cDWrite) {
                dCache->i_FAdr = ddr->o_CAdr;
                dCache->i_FWDat = 0;
                dCache->i_FWE = 0;
                dCache->i_FRE = ddr->o_CRE;
                dCache->i_FLA = ddr->o_CLA;
                dCache->i_FRAck = 0;
                dCache->i_FWAck = ddr->o_WAck;
                ddr->i_WRq = dCache->o_FWReq;
                ddr->i_CRDat = dCache->o_FWDat;
            } else {
                dCache->i_FAdr = 0;
                dCache->i_FWDat = 0;
                dCache->i_FWE = 0;
                dCache->i_FRE = 0;
                dCache->i_FLA = 0;
                dCache->i_FRAck = 0;
                dCache->i_FWAck = 0;
            }


        }

        if (iCache) {
            if (req == cICache) {
                iCache->i_FAdr = ddr->o_CAdr;
                iCache->i_FWDat = ddr->o_CWDat;
                iCache->i_FWE = ddr->o_CWE;
                iCache->i_FLA = ddr->o_CLA;
                iCache->i_FRAck = ddr->o_RAck;
                ddr->i_RRq = iCache->o_FRReq;
            } else {
                iCache->i_FAdr = 0;
                iCache->i_FWDat = 0;
                iCache->i_FWE = 0;
                iCache->i_FLA = 0;
                iCache->i_FRAck = 0;
            }
        }

        if (ddr->o_CLA) {
            req = cNone;
        }

        return;
    }

    // Handle new D cache write request (on full queue)
    if (dCache && dCache->o_FWReq && dCache->o_FQFull) {
        reqAdr = dCache->o_FWAdr;
        ddr->i_Adr = reqAdr;
        req = cDWrite;
        goto request;
    }

    if (dCache && dCache->o_FRReq) {  // Handle new D cache request
        reqAdr = dCache->o_FRAdr;
        ddr->i_Adr = reqAdr;
        req = cDCache;
        goto request;
    }

    if (iCache && iCache->o_FRReq) {  // Handle new I cache request
        reqAdr = iCache->o_FRAdr;
        ddr->i_Adr = reqAdr;
        req = cICache;
        goto request;
    }

    if (dCache && dCache->o_FWReq) {  // Handle new D cache write request
        reqAdr = dCache->o_FWAdr;
        ddr->i_Adr = reqAdr;
        req = cDWrite;
        goto request;
    }

}


/**
 * @brief Log the activity
 *
 */
void FrontSideBus::log(void)
{
    Log::logSrc("   FSB   ", COLOR_BLUE);
    switch (req) {
        case cDCache:
        Log::log("D cache read ");
        Log::logHex(reqAdr, COLOR_MAGENTA, 8);
        Log::log("\n");
        break;
        case cICache:
        Log::log("I cache read ");
        Log::logHex(reqAdr, COLOR_MAGENTA, 8);
        Log::log("\n");
        break;
        case cDWrite:
        Log::log("D cache write ");
        Log::logHex(reqAdr, COLOR_MAGENTA, 8);
        Log::log("\n");
        break;
        default:
        Log::log("Idle cycle\n");
        break;
    }
}


/**
 * @brief Log the activity
 *
 */
void FrontSideBus::logJson(void)
{
    Log::log("\"mf\":\"");
    switch (req) {
        case cDCache:
        Log::log("D cache read ");
        Log::logHex(reqAdr, 8);
        break;
        case cICache:
        Log::log("I cache read ");
        Log::logHex(reqAdr, 8);
        break;
        case cDWrite:
        Log::log("D cache write ");
        Log::logHex(reqAdr, 8);
        break;
        default:
        Log::log("Idle cycle");
        break;
    }
    Log::log("\",");
}
