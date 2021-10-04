/**
 * INSTRUCTION PIPELINE
 * 
 * The pipeline cconsists of 5 stages:
 *  - Fetch
 *  - Decode
 *  - Execute
 *  - Memory Access
 *  - Write Back
 * 
 */
#include "../common/config.h"
#include "../common/log.h"
#include "pipeline.h"
#include <string>


// Mnemonic strings
std::string mnemonic[] = {
    "LUI  ", "AUIPC", "JAL  ", "JALR ", "BEQ  ", "BNE  ", "BLT  ", "BGE  ",
    "BLTU ", "BGEU ", "LB   ", "LH   ", "LW   ", "LBU  ", "LHU  ", "SB   ",
    "SH   ", "SW   ", "ADDI ", "SLTI ", "SLTIU", "XORI ", "ORI  ", "ANDI ",
    "SLLI ", "SRLI ", "SRAI ", "ADD  ", "SUB  ", "SLL  ", "SLT  ", "SLTU ",
    "XOR  ", "SRL  ", "SRA  ", "OR   ", "AND  ", "-----"
};



/**
 * @brief Get format of a given opcode
 * 
 */
unsigned InstructionPipeline::getFormat(unsigned op)
{
    switch (op & 0x7F) {
        
        // Format U
        case 0b0110111: 
        case 0b0010111: 
        return FormatU;

        // Format J
        case 0b1100111:
        return FormatJ;

        // Format B
        case 0b1100011:
        return FormatB;

        // Format I
        case 0b0000011:
        case 0b0010011:
        return FormatI;

        // Format S
        case 0b0100011:
        return FormatI;
        
        // Format R
        case 0b0110011:
        return FormatR;

        // Invalid format
        default: 
        return 6;

    }
}



/**
 * @brief Get immediate value from a given opcode
 * 
 */
unsigned InstructionPipeline::getImmediate(unsigned op)
{
    switch (getFormat(op)) {
        
        default:
        return 0;

        case FormatI:
        return op >> 20;

        case FormatS:
        return ((op >> 20) & 0xFE0) | (op & 0x1E);

        case FormatB:
        return ((op >> 19) & 0x1000) | ((op << 4) & 0x800) | ((op >> 20) & 0x7E0) | (op & 0x1F);

        case FormatU: 
        return (op & 0xFFFFF000);

        case FormatJ:
        return ((op >> 12) & 1) | ((op >> 20) & 0x7FE) | ((op >> 9) & 0xF00) | (op & 0xFF000); 

    }
}



/**
 * @brief Get mnemonic for a given opcode
 * 
 */
unsigned InstructionPipeline::getMnemonic(unsigned op)
{

    switch (op & 0x7F) {
        
        case 0x37: return 0;  // LUI
        case 0x17: return 1;  // AUIPC
        case 0x6F: return 2;  // JAL
        case 0x67: return 3;  // JALR

    }

    switch (op & 0x707F) {
        
        case 0x0063: return 4;   // BEQ
        case 0x1063: return 5;   // BNE
        case 0x4063: return 6;   // BLT
        case 0x5063: return 7;   // BGE
        case 0x6063: return 8;   // BLTU
        case 0x7063: return 9;   // BGEU
        case 0x0003: return 10;  // LB
        case 0x1003: return 11;  // LH
        case 0x2003: return 12;  // LW
        case 0x4003: return 13;  // LBU
        case 0x5003: return 14;  // LHU
        case 0x0023: return 15;  // SB
        case 0x1023: return 16;  // SH
        case 0x2023: return 17;  // SW
        case 0x0013: return 18;  // ADDI
        case 0x2013: return 19;  // SLTI
        case 0x3013: return 20;  // SLTIU
        case 0x4013: return 21;  // XORI
        case 0x6013: return 22;  // ORI
        case 0x7013: return 23;  // ANDI

    }

    switch (op & 0x4000707F) {

        case 0x00001013: return 24;  // SLLI
        case 0x00005013: return 25;  // SRLI
        case 0x40005013: return 26;  // SRAI
        case 0x00000033: return 27;  // ADD
        case 0x40000033: return 28;  // SUB
        case 0x00001033: return 29;  // SLL
        case 0x00002033: return 30;  // SLT
        case 0x00003033: return 31;  // SLTU
        case 0x00004033: return 32;  // XOR
        case 0x00005033: return 33;  // SRL
        case 0x40005033: return 34;  // SRA
        case 0x00006033: return 35;  // OR
        case 0x00007033: return 36;  // AND

    }

    return 37;

}



/**
 * @brief Update function for pipeline
 * 
 */
void InstructionPipeline::Update(void)
{
    if (i_ClockEnable && i_Reset) {  // If pipeline gets cleared

        // Clear validation signals
        n_WriteBackValid = 0;
        n_MemoryAccessValid = 0;
        n_ExecuteValid = 0;
        n_DecodeValid = 0;
        n_FetchValid = 0;
       
       return;
    }

    if (i_ClockEnable) {  // If pipeline not stalled

        // Advande opcodes in pipeline
        n_WriteBackOpcode = n_MemoryAccessOpcode;
        n_MemoryAccessOpcode = n_ExecuteOpcode;
        n_ExecuteOpcode = n_DecodeOpcode;
        n_DecodeOpcode = n_FetchOpcode;
        n_FetchOpcode = i_InstructionInput;

        // Advance addresses in pipeline
        n_WriteBackAddress = n_MemoryAccessAddress;
        n_MemoryAccessAddress = n_ExecuteAddress;
        n_ExecuteAddress = n_DecodeAddress;
        n_DecodeAddress = n_FetchAddress;
        n_FetchAddress = i_InstructionAddress;

        // Advance validation signals
        n_WriteBackValid = n_MemoryAccessValid;
        n_MemoryAccessValid = n_ExecuteValid;
        n_ExecuteValid = n_DecodeValid;
        n_DecodeValid = n_FetchValid;
        n_FetchValid = 1;

        // Update formats
        n_WriteBackFormat = getFormat(n_WriteBackOpcode);
        n_MemoryAccessFormat = getFormat(n_MemoryAccessOpcode);
        n_ExecuteFormat = getFormat(n_ExecuteOpcode);
        n_DecodeFormat = getFormat(n_DecodeOpcode);
        n_FetchFormat = getFormat(n_FetchOpcode);

        // Update immediates
        n_WriteBackImmediate = getImmediate(n_WriteBackOpcode);
        n_MemoryAccessImmediate = getImmediate(n_MemoryAccessOpcode);
        n_ExecuteImmediate = getImmediate(n_ExecuteOpcode);
        n_DecodeImmediate = getImmediate(n_DecodeOpcode);
        n_FetchImmediate = getImmediate(n_FetchOpcode);

    }
}



/**
 * @brief Update ports function for pipeline
 * 
 */
void InstructionPipeline::UpdatePorts(void)
{
    o_FetchOpcode           = n_FetchOpcode;
    o_FetchAddress          = n_FetchAddress;
    o_FetchImmediate        = n_FetchImmediate;
    o_FetchFormat           = n_FetchFormat;
    o_FetchValid            = n_FetchValid;

    o_DecodeOpcode          = n_DecodeOpcode;
    o_DecodeAddress         = n_DecodeAddress;
    o_DecodeImmediate       = n_DecodeImmediate;
    o_DecodeFormat          = n_DecodeFormat;
    o_DecodeValid           = n_DecodeValid;

    o_ExecuteOpcode         = n_ExecuteOpcode;
    o_ExecuteAddress        = n_ExecuteAddress;
    o_ExecuteImmediate      = n_ExecuteImmediate;
    o_ExecuteFormat         = n_ExecuteFormat;
    o_ExecuteValid          = n_ExecuteValid;

    o_MemoryAccessOpcode    = n_MemoryAccessOpcode;
    o_MemoryAccessAddress   = n_MemoryAccessAddress;
    o_MemoryAccessImmediate = n_MemoryAccessImmediate;
    o_MemoryAccessFormat    = n_MemoryAccessFormat;
    o_MemoryAccessValid     = n_MemoryAccessValid;

    o_WriteBackOpcode       = n_WriteBackOpcode;
    o_WriteBackAddress      = n_WriteBackAddress;
    o_WriteBackImmediate    = n_WriteBackImmediate;
    o_WriteBackFormat       = n_WriteBackFormat;
    o_WriteBackValid        = n_WriteBackValid;
}



/**
 * @brief Logging function for instruction pipeline
 * 
 */
void InstructionPipeline::log(void)
{

    Log::logSrc("  PIPE   ", COLOR_GREEN);
    Log::log("IF    ID    EX    MEM   WB  \n");
    Log::logSrc("  PIPE   ", COLOR_GREEN);
    Log::log(mnemonic[getMnemonic(n_FetchOpcode)], COLOR_YELLOW);
    Log::log(" ");
    Log::log(mnemonic[getMnemonic(n_DecodeOpcode)], COLOR_YELLOW);
    Log::log(" ");
    Log::log(mnemonic[getMnemonic(n_ExecuteOpcode)], COLOR_YELLOW);
    Log::log(" ");
    Log::log(mnemonic[getMnemonic(n_MemoryAccessOpcode)], COLOR_YELLOW);
    Log::log(" ");
    Log::log(mnemonic[getMnemonic(n_WriteBackOpcode)], COLOR_YELLOW);
    Log::log("\n");

}