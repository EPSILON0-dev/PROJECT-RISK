/**
 * This is a test for basic program counter functionality
 *
 */

#include "../common/log.h"
#include "../cpu/pc.h"

ProgramCounter pc;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        pc.log();
        pc.Update();
        pc.UpdatePorts();
    }
}

int main()
{
    Log::log("\n[>>>>>>>>>] Execute 16 instructions\n\n");
    pc.i_ClockEnable = 1;
    Update(16);

    Log::log("\n[>>>>>>>>>] Block for 2 cycles\n\n");
    pc.i_ClockEnable = 0;
    Update(2);

    Log::log("\n[>>>>>>>>>] Branch to 0x55AA5500\n\n");
    pc.i_BranchAddress = 0x55AA5500;
    pc.i_ClockEnable = 1;
    pc.i_Branch = 1;
    Update();
    Log::log("\n[>>>>>>>>>] Execute 16 instructions\n\n");
    pc.i_Branch = 0;
    Update(16);

    Log::log("\n[>>>>>>>>>] Reset\n\n");
    pc.i_Reset = 1;
    Update();
    Log::log("\n[>>>>>>>>>] Execute 16 instructions\n\n");
    pc.i_Reset = 0;
    Update(16);

    return 0;
}