/**
 * This is a test for basic branch conditioner functionality
 *
 */
#include "../common/log.h"
#include "../cpu/branch.h"

BranchConditioner bc;

void Update(unsigned n = 1)
{
    for (unsigned i = 0; i < n; i++) {
        bc.Update();
        bc.UpdatePorts();
        bc.log();
    }
}

int main()
{
  
    Log::log("\n[>>>>>>>>>] Unconditional branches\n\n");
    bc.i_OpCode = 0x67;
    Update();
    bc.i_OpCode = 0x6F;
    Update();

    Log::log("\n[>>>>>>>>>] Taken branches\n\n");
    bc.i_OpCode = 0x0063;
    bc.i_RegData1 = 0x55;
    bc.i_RegData2 = 0x55;
    Update();
    bc.i_OpCode = 0x1063;
    bc.i_RegData1 = 0xAA;
    bc.i_RegData2 = 0x55;
    Update();
    bc.i_OpCode = 0x4063;
    bc.i_RegData1 = 0xFFFFFFFF;
    bc.i_RegData2 = 0x00000001;
    Update();
    bc.i_OpCode = 0x5063;
    bc.i_RegData1 = 0x00000001;
    bc.i_RegData2 = 0xFFFFFFFF;
    Update();
    bc.i_OpCode = 0x6063;
    bc.i_RegData1 = 0x00000001;
    bc.i_RegData2 = 0xFFFFFFFF;
    Update();
    bc.i_OpCode = 0x7063;
    bc.i_RegData1 = 0xFFFFFFFF;
    bc.i_RegData2 = 0x00000001;
    Update();

    Log::log("\n[>>>>>>>>>] Skipped branches\n\n");
    bc.i_OpCode = 0x0063;
    bc.i_RegData1 = 0xAA;
    bc.i_RegData2 = 0x55;
    Update();
    bc.i_OpCode = 0x1063;
    bc.i_RegData1 = 0x55;
    bc.i_RegData2 = 0x55;
    Update();
    bc.i_OpCode = 0x4063;
    bc.i_RegData1 = 0x00000001;
    bc.i_RegData2 = 0xFFFFFFFF;
    Update();
    bc.i_OpCode = 0x5063;
    bc.i_RegData1 = 0xFFFFFFFF;
    bc.i_RegData2 = 0x00000001;
    Update();
    bc.i_OpCode = 0x6063;
    bc.i_RegData1 = 0xFFFFFFFF;
    bc.i_RegData2 = 0x00000001;
    Update();
    bc.i_OpCode = 0x7063;
    bc.i_RegData1 = 0x00000001;
    bc.i_RegData2 = 0xFFFFFFFF;
    Update();

    Log::log("\n[>>>>>>>>>] Irrelevant\n\n");
    bc.i_OpCode = 0x13;
    Update();

    return 0;
}