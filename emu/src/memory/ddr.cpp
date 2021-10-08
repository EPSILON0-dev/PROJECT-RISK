/**
 * This is a file for C++ emulator of the machine
 * 
 */

#include "../common/config.h"
#include "../common/log.h"
#include "ddr.h"



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
    for (unsigned i = 0; i < 16 * 1024 * 1024; i++) ram[i] = (i << 2) | 0x55000000;

    state = cIdle;
    wordIndex = 0;
    currentOperation = read;

    i_Address = 0;
    i_ReadRequest = 0;
    i_WriteRequest = 0;
    i_CacheReadData = 0;

    o_CacheAddress = 0;
    o_CacheWriteData = 0;
    o_CacheWriteEnable = 0;
    o_CacheReadEnable = 0;
    o_CacheLastAccess = 0;

    o_ReadAck = 0;
    o_WriteAck = 0;
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
        n_CacheReadEnable = 0;
        n_CacheLastAccess = 0;
        address = i_Address;
        if (i_ReadRequest || i_WriteRequest) {
            if (i_ReadRequest) {
                currentOperation = read;
                state = (activeRow == getRow(address)) ? cRead : cRow;
            } else {
                currentOperation = write;
                state = (activeRow == getRow(address)) ? cWrite : cRow;
            }
            goto endUpdate;
        }
    }

    if (state == cRow) {
        activeRow = getRow(address);
        state = cRowDelay;
        goto endUpdate;
    }

    if (state == cRowDelay) {
        if (currentOperation == read) {
            state = cRead;
        } else {
            state = cWrite;
        }
        goto endUpdate;
    }

    if (state == cRead) {
        wordIndex = 0;
        n_ReadAck = 1;
        state = cCL1;
        goto endUpdate;
    }

    if (state == cWrite) {
        wordIndex = 1;
        n_WriteAck = 1;
        n_CacheReadEnable = 1;
        n_CacheAddress = address;
        state = cWriting;
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
        n_CacheAddress = address + (wordIndex << 2);
        n_CacheWriteData = ram[((n_CacheAddress & 0x3FFFFFF) >> 2)];
        wordIndex++;
        if (wordIndex == 8) {
            state = cIdle;
            n_CacheLastAccess = 1;
        }
        goto endUpdate;
    }

    if (state == cWriting) {
        n_WriteAck = 0;
        n_CacheAddress = address + (wordIndex << 2);
        if (wordIndex >= 2) {
            ram[((n_CacheAddress & 0x3FFFFFF) >> 2) - 2] = i_CacheReadData;
        }
        wordIndex++;
        if (wordIndex == 8) {
            n_CacheLastAccess = 1;
        }
        if (wordIndex == 9) {
            n_CacheLastAccess = 0;
            state = cIdle;
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
    o_CacheAddress = n_CacheAddress;
    o_CacheWriteData = n_CacheWriteData;
    o_CacheLastAccess = n_CacheLastAccess;
    o_CacheWriteEnable = n_CacheWriteEnable;
    o_CacheReadEnable = n_CacheReadEnable;
    o_ReadAck = n_ReadAck;
    o_WriteAck = n_WriteAck;
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
        Log::logHex(getRow(address), COLOR_MAGENTA, 4);
        Log::log("\n");
        break;

        case cRowDelay:
        Log::log("Waiting for activate\n");
        break;

        case cRead:
        Log::log("Reading column ");
        Log::logHex(getColumn(address), COLOR_MAGENTA, 3);
        Log::log("\n");
        break;

        case cWrite:
        Log::log("Writing column ");
        Log::logHex(getColumn(address), COLOR_MAGENTA, 3);
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

        case cWriting:
        Log::log("Writing word ");
        Log::logDec(wordIndex - 1);
        Log::log("\n");
        break;

        default:
        Log::log("Idle cycle\n");
        break;

    }

}