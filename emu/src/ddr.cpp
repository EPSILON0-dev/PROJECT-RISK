/**
 * This is a file for C++ emulator of the machine
 * 
 */

#include "log.h"
#include "ddr.h"
#include "config.h"



/**
 * @brief Constructor
 * 
 */
MainRam::MainRam(void)
{
    Log::logSrc("   DDR   ", COLOR_BLUE);
    Log::log("Sending the configuration to the DDR memory\n");
    Log::logSrc("   DDR   ", COLOR_BLUE);
    Log::log("Bank ");
    Log::log("0x0", COLOR_MAGENTA);
    Log::log(", address ");
    Log::log("0x0024", COLOR_MAGENTA);
    Log::log(", all control lines low\n");
    
    ram = new unsigned[16 * 1024 * 1024];
    for (unsigned i = 0; i < 16 * 1024 * 1024; i++) ram[i] = (i << 2) | 0x5A000000;

    state = cIdle;
    wordIndex = 0;

    i_ReadAddress = 0;
    i_ReadRequest = 0;
    o_CacheWriteAddress = 0;
    o_CacheWriteData = 0;
    o_CacheWriteEnable = 0;
}



/**
 * @brief destructor
 * 
 */
MainRam::~MainRam(void) 
{
    delete[] ram;
}



unsigned MainRam::getBank(unsigned a)
{
    return (a >> 24) & 0x3;
}

unsigned MainRam::getRow(unsigned a)
{
    return (a >> 11) & 0x1FFF;
}

unsigned MainRam::getColumn(unsigned a)
{
    return (a >> 1) & 0x3FF;
}



/**
 * @brief Update function for DDR controller
 * 
 */
void MainRam::Update(void) 
{
    
    if (state == cIdle) {
        n_CacheWriteEnable = 0;
        n_CacheLastWrite = 0;
        readAddress = i_ReadAddress;
        if (i_ReadRequest) {
            state = (activeRow == getRow(readAddress)) ? cRead : cRow;
            goto endUpdate;
        }
    }

    if (state == cRow) {
        activeRow = getRow(readAddress);
        state = cRowDelay;
        goto endUpdate;
    }

    if (state == cRowDelay) {
        state = cRead;
        goto endUpdate;
    }

    if (state == cRead) {
        wordIndex = 0;
        n_ReadAck = 1;
        state = cCL1;
        goto endUpdate;
    }

    if (state == cCL1) {
        state = cCL2;
        goto endUpdate;
    }

    if (state == cCL2) {
        state = cReading;
        goto endUpdate;
    }

    if (state == cReading) {
        n_ReadAck = 0;
        n_CacheWriteEnable = 1;
        n_CacheWriteAddress = readAddress + (wordIndex << 2);
        n_CacheWriteData = ram[(n_CacheWriteAddress >> 2)];
        wordIndex++;
        if (wordIndex == 8) {
            state = cIdle;
            n_CacheLastWrite = 1;
        }
        goto endUpdate;
    }

    endUpdate:
    return;

}



/**
 * @brief Output ports update function for data cache
 * 
 */
void MainRam::UpdatePorts(void) 
{
    o_CacheWriteAddress = n_CacheWriteAddress;
    o_CacheWriteData = n_CacheWriteData;
    o_CacheLastWrite = n_CacheLastWrite;
    o_CacheWriteEnable = n_CacheWriteEnable;
    o_ReadAck = n_ReadAck;
}



/**
 * @brief Logging function for front side bus
 * 
 */
void MainRam::log(void)
{
    Log::logSrc("   DDR   ", COLOR_BLUE);
    
    switch (state) {

        case cRow:
        Log::log("Activate row ");
        Log::logHex(getRow(readAddress), COLOR_MAGENTA, 4);
        Log::log("\n");
        break;

        case cRowDelay:
        Log::log("Waiting for activate\n");
        break;

        case cRead:
        Log::log("Reading column ");
        Log::logHex(getColumn(readAddress), COLOR_MAGENTA, 3);
        Log::log("\n");
        break;

        case cCL1:
        Log::log("Waiting for read\n");
        break;

        case cCL2:
        Log::log("Waiting for read\n");
        break;

        case cReading:
        Log::log("Reading word ");
        Log::logDec(wordIndex);
        Log::log("\n");
        break;

        default:
        Log::log("Idle cycle\n");
        break;

    }

}



/**
 * @brief internal function for read FSM
 * 
 */
/*void DDR::updateRead(void)
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
}*/