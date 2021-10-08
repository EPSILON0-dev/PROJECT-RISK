/**
 * TOP CPU BLOCK
 * 
 */
#include "alu.h"
#include "branch.h"
#include "cpu.h"
#include "pc.h"
#include "pipeline.h"
#include "regs.h"
#include "../common/config.h"
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"



// Instances of modules
ArythmeticLogicUnit alu;
BranchConditioner bc;
InstructionPipeline ip;
ProgramCounter pc;
RegisterSet rs;
InstructionCache* ic;
DataCache* dc;



/**
 * @brief Constructor for the CPU
 * 
 */
CentralProcessingUnit::CentralProcessingUnit(void)
{ 
    i_Reset = 0; 
}



/**
 * @brief This function supplies the class pointers for the CPU
 * 
 */
void CentralProcessingUnit::loadPointers(void* icache, void* dcache)
{
    ic = (InstructionCache*)icache;
    dc = (DataCache*)dcache;
}



/**
 * @brief Update function for CPU
 * 
 */
void CentralProcessingUnit::Update(void)
{

    static unsigned alu_TempRegister;
    static unsigned pc_TempRegister;
    static unsigned auipc_TempRegister;

    ip.log();

    // DECODER
    bool dc_dc_jal = ((ip.o_DecodeOpcode & 0x7F) == 0b1101111);
    bool dc_wb_jal = ((ip.o_WriteBackOpcode & 0x7F) == 0b1101111);
    bool dc_dc_jalr = ((ip.o_DecodeOpcode & 0x7F) == 0b1100111);
    bool dc_ex_jalr = ((ip.o_ExecuteOpcode & 0x7F) == 0b1100111);
    bool dc_wb_jalr = ((ip.o_WriteBackOpcode & 0x7F) == 0b1100111);
    bool dc_ex_imm_op_32 = ((ip.o_ExecuteOpcode & 0x7F) == 0b0010011);
    bool dc_wb_imm_op_32 = ((ip.o_WriteBackOpcode & 0x7F) == 0b0010011);
    bool dc_wb_op_32 = ((ip.o_WriteBackOpcode & 0x7F) == 0b0110011);
    bool dc_wb_lui = ((ip.o_WriteBackOpcode & 0x7F) == 0b0110111);
    bool dc_ex_auipc = ((ip.o_ExecuteOpcode & 0x7F) == 0b0010111);
    bool dc_wb_auipc = ((ip.o_WriteBackOpcode & 0x7F) == 0b0010111);

    bool dc_ip_Advance = ic->o_CacheValidData; // TODO
    
    unsigned dc_alu_OpCode3 = (ip.o_ExecuteOpcode >> 12) & 0x7;
    unsigned dc_alu_OpCode7 = (ip.o_ExecuteOpcode >> 25) & 0x7F;
    unsigned dc_alu_InputB = (dc_ex_imm_op_32)? ip.o_ExecuteImmediate : rs.o_ReadDataB;
    
    bool dc_pc_Advance = ic->o_CacheValidData; // TODO
    unsigned dc_pc_BranchAddress = ((dc_ex_jalr)? rs.o_ReadDataA : ip.o_ExecuteAddress) + 
        ip.o_ExecuteImmediate;
    
    unsigned dc_rs_ReadAddressA = (ip.o_DecodeOpcode >> 15) & 0x1F;
    unsigned dc_rs_ReadAddressB = (ip.o_DecodeOpcode >> 20) & 0x1F;
    unsigned dc_rs_WriteAddress = (ip.o_WriteBackOpcode >> 7) & 0x1F;
    unsigned dc_rs_WriteData = (dc_wb_auipc)? auipc_TempRegister : (dc_wb_lui)? ip.o_WriteBackImmediate : 
        (dc_wb_jal | dc_wb_jalr) ? pc_TempRegister : alu_TempRegister;  // TODO
    bool dc_rs_WriteEnable = dc_wb_imm_op_32 | dc_wb_op_32 | dc_wb_jal | dc_wb_jalr | dc_wb_lui | dc_wb_auipc;  // TODO
    bool dc_rs_ClockEnable = ic->o_CacheValidData; // TODO
    // DECODER

    if (dc_dc_jal | dc_dc_jalr) {
        pc_TempRegister = pc.o_Address;
    }

    if (dc_ex_auipc) {
        auipc_TempRegister = dc_pc_BranchAddress;
    }

    bc.i_OpCode = ip.o_ExecuteOpcode;
    bc.i_RegDataA = rs.o_ReadDataA;
    bc.i_RegDataB = rs.o_ReadDataB;
    
    bc.Update();

    alu.i_Immediate = dc_ex_imm_op_32;
    alu.i_InputA = rs.o_ReadDataA;
    alu.i_InputB = dc_alu_InputB;
    alu.i_OpCode3 = dc_alu_OpCode3;
    alu.i_OpCode7 = dc_alu_OpCode7;

    pc.i_ClockEnable = dc_pc_Advance;
    pc.i_Reset = i_Reset;
    pc.i_Branch = bc.o_BranchEnable;
    pc.i_BranchAddress = dc_pc_BranchAddress;

    ip.i_ClockEnable = dc_ip_Advance;
    ip.i_Reset = i_Reset;
    ip.i_Branch = bc.o_BranchEnable;
    ip.i_InstructionAddress = pc.o_Address;
    ip.i_InstructionInput = ic->o_CacheReadData;

    rs.i_ClockEnable = dc_rs_ClockEnable;
    rs.i_AddressReadA = dc_rs_ReadAddressA;
    rs.i_AddressReadB = dc_rs_ReadAddressB;
    rs.i_AddressWrite = dc_rs_WriteAddress;
    rs.i_WriteEnable = dc_rs_WriteEnable;
    rs.i_WriteData = dc_rs_WriteData;

    alu_TempRegister = alu.o_Output;

    alu.Update();
    pc.Update();
    ip.Update();
    rs.Update();

    alu.UpdatePorts();
    pc.UpdatePorts();
    ip.UpdatePorts();
    rs.UpdatePorts();

    alu.log();
    bc.log();
    pc.log();
    rs.log();

    ic->i_CacheReadEnable = 1;
    ic->i_CacheAddress = pc.o_Address;

}



/**
 * @brief Log function for CPU
 * 
 */
void CentralProcessingUnit::log(void)
{
    rs.logContent();
}
