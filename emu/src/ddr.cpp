/**
 * This is a file for C++ emulator of the machine
 * 
 */

#include "log.h"
#include "ddr.h"
#include "config.h"
#include "debug.h"

/**
 * @brief Constructor
 * 
 */
DDR::DDR(void)
{
    // During initialization configuration sequence have to be sent 
    // Here it's just a debug print but in the final VHDL code it will have to
    //  be done as special states in FSM, only triggered on reset or boot.
    // Data has to be sent on address (and bank select) lines, configuration 
    //  value should be 0x0 for bank lines and 0x0024 for address lines.
    #ifdef DDR_DEBUG
        Log::logSrc("   DDR   ", COLOR_BLUE);
        Log::log("Sending the configuration to the DDR memory\n");
        Log::logSrc("   DDR   ", COLOR_BLUE);
        Log::log("Bank ");
        Log::log("0x0", COLOR_MAGENTA);
        Log::log(", address ");
        Log::log("0x0024", COLOR_MAGENTA);
        Log::log(", all control lines low\n");
    #endif
    
    // Allocate 64 MB of memory, it's a big alloc
    memoryArray = new unsigned[16 * 1024 * 1024];

    // Fill each word with it's address
    for (unsigned i = 0; i < 16 * 1024 * 1024; i++)
        memoryArray[i] = i | 0x5A000000;
    
    // Enter idle status
    status = cIdle;
    fsm = crFsmIdle;
    burstByte = 0;
}

/**
 * @brief destructor
 * 
 */
DDR::~DDR(void) 
{
    delete[] memoryArray;
}

/**
 * @brief This function performs one clock cycle of DDR operation
 * 
 */
void DDR::Update(void) 
{
    // If in idle return
    if (status == cIdle) return;

    // If status is reading act according to read FSM
    if (status == cRead) updateRead();
}

/**
 * @brief internal function for read FSM
 * 
 */
void DDR::updateRead(void)
{
    switch (fsm) {
        default:
            if (activeRow == readRow) {
                #ifdef DDR_FSM_DEBUG 
                    Log::logSrc("   DDR   ", COLOR_BLUE);
                    Log::log("Entering read FSM, active row match\n");
                #endif
                fsm = crRequest;
            } else {
                #ifdef DDR_FSM_DEBUG 
                    Log::logSrc("   DDR   ", COLOR_BLUE);
                    Log::log("Entering read FSM, active row doesn't match\n");
                #endif
                fsm = crRowActivate;
            }
            break;

        case crRowActivate:
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Activating ");
                Log::logHex(readRow, COLOR_MAGENTA, 4);
                Log::log(" row\n");
            #endif
            activeRow = readRow;
            fsm = crActivateDelay;
            break;

        case crActivateDelay:
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Row activated\n");
            #endif
            fsm = crRequest;
            break;

        case crRequest:
            burstByte = 0;
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Requesting read from bank ");
                Log::logDec(readBank);
                Log::log(" column ");
                Log::logHex(readColumn, COLOR_MAGENTA, 3);
                Log::log("\n");
            #endif
            fsm = crCL1;
            break;

        case crCL1:
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Waiting for data...\n");
            #endif
            fsm = crCL2;
            break;

        case crCL2:
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Waiting for data...\n");
            #endif
            fsm = crReading;
            break;

        case crReading:
            #ifdef DDR_FSM_DEBUG 
                Log::logSrc("   DDR   ", COLOR_BLUE);
                Log::log("Reading word ");
                Log::logDec(burstByte);
                Log::log(": ");
                Log::logHex(memoryArray[readAddress + (burstByte << 2)], COLOR_MAGENTA, 8);
                Log::log("\n");
            #endif
            readData = memoryArray[(readAddress >> 2) + burstByte];
            if (burstByte == 7) {
                #ifdef DDR_DEBUG
                    Log::logSrc("   DDR   ", COLOR_BLUE);
                    Log::log("completed request address for block ");
                    Log::logHex(readAddress, COLOR_MAGENTA, 8);
                    Log::log("\n");
                #endif
                fsm = crFsmIdle;
                status = cIdle;
            }
            burstByte++;
            break;
    }
}

/**
 * @brief This function performs a read from DDR memory
 * @param address Address of block read from memory
 * 
 */
void DDR::performRead(unsigned address)
{
    #ifdef DDR_DEBUG
        Log::logSrc("   DDR   ", COLOR_BLUE);
        Log::log("receiver read request for block ");
        Log::logHex(address, COLOR_MAGENTA, 8);
        Log::log("\n");
    #endif

    // Decode the address
    readAddress = address;
    readBank = (address >> 24) & 0x3;
    readRow = (address >> 11) & 0x1FFF;
    readColumn = (address >> 1) & 0x3FF;

    // Enter reading state
    status = cRead;
}