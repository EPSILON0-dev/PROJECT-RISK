/**
 * This is a test for basic cache functionality
 *
 */

#include "../common/config.h"
#include "../common/log.h"
#include "../memory/ddr.h"

MainRam ddr;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        ddr.log();
        Log::logSrc("   DDR   ", COLOR_BLUE);
        Log::log("o_CacheAddress: ");
        Log::logHex(ddr.o_CacheAddress, COLOR_MAGENTA, 8);
        Log::log("  o_CacheWriteData: ");
        Log::logHex(ddr.o_CacheWriteData, COLOR_MAGENTA, 8);
        Log::log("  o_CacheLastAccess: ");
        Log::logDec(ddr.o_CacheLastAccess, COLOR_MAGENTA);
        Log::log("\n");
        Log::logSrc("   DDR   ", COLOR_BLUE);
        Log::log("o_CacheWriteEnable: ");
        Log::logDec(ddr.o_CacheWriteEnable, COLOR_MAGENTA);
        Log::log("  o_CacheReadEnable: ");
        Log::logDec(ddr.o_CacheReadEnable, COLOR_MAGENTA);
        Log::log("  o_ReadAck: ");
        Log::logDec(ddr.o_ReadAck, COLOR_MAGENTA);
        Log::log("  o_WriteAck: ");
        Log::logDec(ddr.o_WriteAck, COLOR_MAGENTA);
        Log::log("\n");

        ddr.Update();
        ddr.UpdatePorts();
    }
}

int main()
{

    Log::log("\n");

    ddr.i_Address = 0x0000000;
    ddr.i_ReadRequest = 1;
    Update(2);
    ddr.i_ReadRequest = 0;
    Update(22);
    Log::log("\n");

    ddr.i_Address = 0x1A5A5A0;
    ddr.i_ReadRequest = 1;
    Update(2);
    ddr.i_ReadRequest = 0;
    Update(20);
    Log::log("\n");

    ddr.i_Address = 0x1A5A5A0;
    ddr.i_WriteRequest = 1;
    Update(2);
    ddr.i_WriteRequest = 0;
    Update(20);
    Log::log("\n");

    ddr.i_Address = 0x0000000;
    ddr.i_WriteRequest = 1;
    Update(2);
    ddr.i_WriteRequest = 0;
    Update(22);
    Log::log("\n");

    return 0;
}