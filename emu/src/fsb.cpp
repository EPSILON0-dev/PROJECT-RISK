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
#include "log.h"
#include "cache.h"
#include "fsb.h"

#define DEBUG

extern ReadOnlyCache roCache;

/**
 * @brief This function initializes the Front Side Bus
 * @param readSources specifies the number of unique read sources
 * 
 */
FrontSideBus::FrontSideBus(void)
{
    // Write queue is 32 
    writeQueue = new bool[32];
    writeQueueAddress = new unsigned[32];
    writeQueueStatus = cComplete;
    writeQueuePtr = 0;
    for (unsigned i = 0; i < 32; i++) {
        writeQueue[i] = 0;
        writeQueueAddress[i] = 0;
    }

    // Each read source gets it's own request register
    readRequest = new bool[3];
    readRequestAddress = new unsigned[3];
    readRequestStatus = new char[3];
    readRequestSet = new bool[3];
    for (unsigned i = 0; i < 3; i++) {
        readRequest[i] = 0;
        readRequestAddress[i] = 0;
        readRequestStatus[i] = cComplete;
        readRequestSet[i] = 0;
    }

    // Set initial idle state
    state = cIdle;
    burstByte = 0;
    currentRequest = cNone;
}

/**
 * @brief Destructor
 * 
 */
FrontSideBus::~FrontSideBus(void)
{
    delete[] writeQueue;
    delete[] writeQueueAddress;
    delete[] readRequest;
    delete[] readRequestAddress;
}

/**
 * @brief This function performs one clock cycle of FSB operation
 * 
 */
void FrontSideBus::Update(void)
{
    // TODO: Make this function right

    // If there is any request
    if (writeQueueStatus || readRequest[0] || readRequest[1] || readRequest[2]) {
        
        // If it's write request
        if (!currentRequest) {
            if (writeQueueStatus) {
                // Funny, there's no write requests yet
            } else {
                if (readRequest[0]) currentRequest = cRead0;
                if (readRequest[1]) currentRequest = cRead1;
                if (readRequest[2]) currentRequest = cRead2;
            }
        }

        unsigned index = ((readRequestAddress[0] >> 2) & 0x7F8) + burstByte;
        unsigned data = random();

        // Read FSM like thingi
        if (currentRequest == cRead0) {
            switch (state) {
                default:
                    state = cCas;
                    burstByte = 0;
                    break;
                
                case cCas:
                    state = cRas;
                    burstByte = 0;
                    break;

                case cRas:
                    state = cDelay;
                    burstByte = 0;
                    break;

                case cDelay:
                    state = cRead;
                    burstByte = 0;
                    break;

                case cRead:
                    if (burstByte < 7) {
                        roCache.fsbWriteCache(index, data, readRequestSet[0]);
                        burstByte++;
                    } else {
                        roCache.fsbWriteCache(index, data, readRequestSet[0]);
                        roCache.cacheStatus = roCache.cOk;
                        readRequestStatus[0] = cComplete;
                        readRequest[0] = 0;
                        state = cIdle;
                        #ifdef DEBUG
                            Log::log("[  FSB  ]: ");
                            Log::log("Read request ");
                            Log::logDec(0);
                            Log::log(" completed\n");
                        #endif
                    }
                    break;
            }
        }
    }
}

/**
 * @brief This function handles write calls
 * @param blockAddress address of the block to be written
 * 
 */
void FrontSideBus::callWrite(unsigned blockAddress)
{
    // Add request to the queue
    writeQueue[(unsigned)writeQueuePtr] = 1;
    writeQueueAddress[(unsigned)writeQueuePtr] = blockAddress;
    writeQueuePtr++;

    // Log the request
    #ifdef DEBUG
        Log::log("[  FSB  ]: ");
        Log::log("Added write request to the block ");
        Log::logHex(blockAddress, 8);
        Log::log(", position in queue: ");
        Log::logDec(writeQueuePtr);
        Log::log("\n");
    #endif

    // If queue full set "full" status
    // Also lower the read requests priority
    if (writeQueuePtr >= 32) {
        #ifdef DEBUG
            Log::log("[  FSB  ]: ");
            Log::log("Log queue full, raising the priority\n");
        #endif
        writeQueueStatus = cQueueFull;
        for (unsigned i = 0; i < 3; i++) {
            if (readRequestStatus[i]) readRequestStatus[i] = cLowerPriority;
        }

    // If not full set "awaiting" status
    } else {
        writeQueueStatus = cAwaiting;
    }
}

/**
 * @brief This function handles read calls
 * @param blockAddress address of the block to be read
 * @param callerId priority (and ID) of the caller
 * @param secondSet write to second cache set
 * 
 */
void FrontSideBus::callRead(unsigned blockAddress, unsigned char callerId, bool secondSet)
{
    // Add request to the request "queue"
    readRequest[callerId] = 1;
    readRequestSet[callerId] = secondSet;
    readRequestAddress[callerId] = blockAddress;

    // Log the request
    #ifdef DEBUG
        Log::log("[  FSB  ]: ");
        Log::log("Added read request from block ");
        Log::logHex(blockAddress, 8);
        Log::log(", priority: ");
        Log::logDec(callerId);
        Log::log("\n");
    #endif
    
    // Set the status for the request
    // If any of the higher priority requests are active set status to lower priority
    // Set lower priority requests to "low priority" (if active)
    switch (callerId) {
        case 0: // CPU I cache
            if (readRequest[1] || readRequest[2] || writeQueueStatus == cQueueFull) {
                readRequestStatus[0] = cLowerPriority;
            } else {
                readRequestStatus[0] = cAwaiting;
            }
            break;

        case 1: // CPU D cache
            if (readRequest[2] || writeQueueStatus == cQueueFull) {
                readRequestStatus[1] = cLowerPriority;
                if (readRequestStatus[0]) readRequestStatus[0] = cLowerPriority;
            } else {
                readRequestStatus[1] = cAwaiting;
                if (readRequestStatus[0]) readRequestStatus[0] = cLowerPriority;
            }
            break;

        default: // VGA cache
            if (writeQueueStatus == cQueueFull) {
                readRequestStatus[2] = cLowerPriority;
                if (readRequestStatus[1]) readRequestStatus[1] = cLowerPriority;
                if (readRequestStatus[0]) readRequestStatus[0] = cLowerPriority;
            } else {
                readRequestStatus[2] = cAwaiting;
                if (readRequestStatus[1]) readRequestStatus[1] = cLowerPriority;
                if (readRequestStatus[0]) readRequestStatus[0] = cLowerPriority;
            }
            break;
    }
}