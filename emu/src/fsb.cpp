/**
 * This is a file for C++ emulator of the machine
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

#include <random>
#include "ddr.h"
#include "log.h"
#include "icache.h"
#include "dcache.h"
#include "fsb.h"
#include "config.h"

static InstructionCache* iCache;
static DataCache* dCache;
static MainRam* ddr;



/**
 * @brief Constructor
 * 
 */
FrontSideBus::FrontSideBus(void)
{
    requestAddress = 0;
    request = cNone;
}



/**
 * @brief Destructor
 * 
 */
FrontSideBus::~FrontSideBus(void) {}



/**
 * @brief This function supplies the class pointers for the FSB
 * 
 */
void FrontSideBus::loadPointers(void* instructionCache, void* dataCache, void* mainRam)
{
    iCache = (InstructionCache*)instructionCache;
    dCache = (DataCache*)dataCache;
    ddr = (MainRam*)mainRam;
}



/**
 * @brief Update function for front side bus
 * 
 */
void FrontSideBus::Update(void)
{

    if (request) {  // Continue currently serviced request
        
        serviceRequest:

        if (request == cDCache) {
            dCache->i_FsbAddress = ddr->o_CacheWriteAddress;
            dCache->i_FsbWriteData = ddr->o_CacheWriteData;
            dCache->i_FsbWriteEnable = ddr->o_CacheWriteEnable;
            dCache->i_FsbFetchFinished = ddr->o_CacheLastWrite;
            dCache->i_FsbReadAck = ddr->o_ReadAck;
            ddr->i_ReadRequest = dCache->o_FsbReadRequest;
        } else {
            dCache->i_FsbAddress = 0;
            dCache->i_FsbWriteData = 0;
            dCache->i_FsbWriteEnable = 0;
            dCache->i_FsbFetchFinished = 0;
            dCache->i_FsbReadAck = 0;
        }

        if (request == cICache) {
            iCache->i_FsbAddress = ddr->o_CacheWriteAddress;
            iCache->i_FsbWriteData = ddr->o_CacheWriteData;
            iCache->i_FsbWriteEnable = ddr->o_CacheWriteEnable;
            iCache->i_FsbFetchFinished = ddr->o_CacheLastWrite;
            iCache->i_FsbReadAck = ddr->o_ReadAck;
            ddr->i_ReadRequest = iCache->o_FsbReadRequest;
        } else {
            iCache->i_FsbAddress = 0;
            iCache->i_FsbWriteData = 0;
            iCache->i_FsbWriteEnable = 0;
            iCache->i_FsbFetchFinished = 0;
            iCache->i_FsbReadAck = 0;
        }

        if (ddr->o_CacheLastWrite) {
            request = cNone;
        }

        return;
    }

    if (dCache->o_FsbReadRequest) {  // Handle new D cache request
        requestAddress = dCache->o_FsbReadAddress;
        ddr->i_ReadAddress = requestAddress;
        request = cDCache;
        goto serviceRequest;
    }

    if (iCache->o_FsbReadRequest) {  // Handle new I cache request
        requestAddress = iCache->o_FsbReadAddress;
        ddr->i_ReadAddress = requestAddress;
        request = cICache;
        goto serviceRequest;
    }

}



/**
 * @brief Logging function for front side bus
 * 
 */
void FrontSideBus::log(void)
{

    Log::logSrc("   FSB   ", COLOR_BLUE);
    
    switch (request) {
        
        case cDCache:
        Log::log("D cache read ");
        Log::logHex(requestAddress, COLOR_MAGENTA, 8);
        Log::log("\n");
        break;

        case cICache:
        Log::log("I cache read ");
        Log::logHex(requestAddress, COLOR_MAGENTA, 8);
        Log::log("\n");
        break;

        default:
        Log::log("Idle cycle\n");
        break;

    }

}
