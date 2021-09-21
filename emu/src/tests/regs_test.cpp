/**
 * This is a test for basic program counter functionality
 *
 */

#include "../common/log.h"
#include "../cpu/regs.h"

RegisterSet regs;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        regs.log();
        regs.Update();
        regs.UpdatePorts();
    }
}

int main()
{

    Log::log("\n[>>>>>>>>>] Read from 0\n\n");
    regs.i_AddressReadA = 0;
    regs.i_AddressReadB = 0;
    regs.i_AddressWrite = 0;
    regs.i_WriteData = 0;
    regs.i_WriteEnable = 0;
    Update();

    Log::log("\n[>>>>>>>>>] Overwriting 0 register\n\n");
    regs.i_WriteData = 0x55;
    regs.i_WriteEnable = 1;
    Update();
    regs.i_WriteEnable = 0;
    Update();

    Log::log("\n[>>>>>>>>>] Writing to registers\n\n");
    regs.i_WriteData = 0x55;
    regs.i_AddressWrite = 1;
    regs.i_WriteEnable = 1;
    Update();
    regs.i_WriteData = 0xAA;
    regs.i_AddressWrite = 2;
    regs.i_WriteEnable = 1;
    Update();
    regs.i_WriteData = 0xFF;
    regs.i_AddressWrite = 3;
    regs.i_WriteEnable = 1;
    Update();

    Log::log("\n[>>>>>>>>>] Read data from registers\n\n");
    regs.i_WriteData = 0;
    regs.i_WriteEnable = 0;
    regs.i_AddressWrite = 0;
    regs.i_AddressReadA = 1;
    regs.i_AddressReadB = 2;
    Update();
    regs.i_AddressReadA = 3;
    regs.i_AddressReadB = 3;
    Update();

    return 0;
}