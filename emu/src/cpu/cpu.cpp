/**
 * @file cpu.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main CPU File
 * @date 2021-10-08
 * 
 */


#include <iostream>
#include "alu.h"
#include "branch.h"
#include "cpu.h"
#include "decode.h"
#include "regs.h"
#include "mem.h"
#include "../common/config.h"
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"


RegisterSet rs;
InstructionCache* ic;
DataCache* dc;


unsigned if_pc {};        // Program counter value in IF stage

unsigned id_ret {};       // Return PC value from IF with 0x4 added (used for return from JAL and JALR)
unsigned id_pc {};        // PC value from IF without 0x4 added
unsigned id_ir {};        // Instruction loaded from ICACHE

unsigned ex_rd1 {};       // Data read from register rs1 [19:15]
unsigned ex_rd2 {};       // Data read from register rs2 [24:20]
unsigned ex_imm {};       // Immediate value from opcode
unsigned ex_pc {};        // PC value forwarded from ID
unsigned ex_ret {};       // Return PC value forwarded from ID
unsigned ex_c1 {};        // Branch conditioner opcode (id_ir[6:2])
unsigned ex_c2 {};        // ALU B multiplexer (1:ex_imm/0:ex_rd2)
unsigned ex_c3 {};        // ALU A multiplexer (1:ex_pc/0:ex_rd1)
unsigned ex_c4 {};        // ALU opcode (ex_c2, enable, funct3(id_ir[14:12]))
unsigned ex_c5 {};        // DCACHE write enable
unsigned ex_c6 {};        // DCACHE read enable
unsigned ex_c7 {};        // Write back data select
unsigned ex_c8 {};        // Write back address
unsigned ex_c9 {};        // Write back enable

unsigned mem_rd2 {};      // Data read from register rs2 [24:20]
unsigned mem_alu {};      // Result of ALU operation
unsigned mem_ret {};      // Return PC value forwarded from ID
unsigned mem_c5 {};       // DCACHE write enable
unsigned mem_c6 {};       // DCACHE read enable
unsigned mem_c7 {};       // Write back data select
unsigned mem_c8 {};       // Write back address
unsigned mem_c9 {};       // Write back enable

unsigned wb_wb {};        // Write back data
unsigned wb_c8 {};        // Write back address
unsigned wb_c9 {};        // Write back enable

unsigned if_c_pc_inc {};  // PC increment enable

unsigned id_c_imm {};     // (COMBINATIONAL) ex_imm
unsigned id_c_rd1 {};     // (COMBINATIONAL) ex_rd1
unsigned id_c_rd2 {};     // (COMBINATIONAL) ex_rd2

bool id_c_load {};        // Load operation
bool id_c_store {};       // Store operation
bool id_c_jalr {};        // Jump And Link Register operation
bool id_c_jal {};         // Jump And Link operation
bool id_c_op_imm {};      // Immediate arythmetic operation
bool id_c_op {};          // Arythmetic operation
bool id_c_auipc {};       // Add Upper Immediate to PC operation
bool id_c_lui {};         // Load Upper Immediate operation
bool id_c_branch {};      // Branch operation
bool id_c_h_rs1 {};       // rs1 can generate data hazards
bool id_c_h_rs2 {};       // rs2 can generate data hazards

unsigned id_c_op_ok {};   // Opcode is OK
unsigned id_c_c1 {};      // (COMBINATIONAL) ex_c1
unsigned id_c_c2 {};      // (COMBINATIONAL) ex_c2
unsigned id_c_c3 {};      // (COMBINATIONAL) ex_c3
unsigned id_c_c4 {};      // (COMBINATIONAL) ex_c4
unsigned id_c_c5 {};      // (COMBINATIONAL) ex_c5
unsigned id_c_c6 {};      // (COMBINATIONAL) ex_c6
unsigned id_c_c7 {};      // (COMBINATIONAL) ex_c7
unsigned id_c_c8 {};      // (COMBINATIONAL) ex_c8
unsigned id_c_c9 {};      // (COMBINATIONAL) ex_c9

unsigned ex_c_alu_a {};   // Multiplexed ALU input A
unsigned ex_c_alu_b {};   // Multiplexed ALU input B
unsigned ex_c_alu {};     // (COMBINATIONAL) ALU output
unsigned ex_c_br_en {};   // (COMBINATIONAL) Branch enable

bool hz_br {};            // Branch hazard
bool hz_dat {};           // Data hazard

bool ce_if  {};           // Clock enable for IF
bool ce_id  {};           // Clock enable for ID
bool ce_ex  {};           // Clock enable for EX
bool ce_mem {};           // Clock enable for MEM
bool ce_wb  {};           // Clock enable for WB


/**
 * @brief Load the memory class pointers
 * 
 * @param icache Instruction Cache pointer
 * @param dcache Data Cache pointer
 */
void CentralProcessingUnit::loadPointers(void* icache, void* dcache)
{
    ic = (InstructionCache*)icache;
    dc = (DataCache*)dcache;
}


/**
 * @brief First of the two updates, computes combinational logic
 * 
 */
void CentralProcessingUnit::UpdateCombinational(void)
{
    
    /*********************************  FETCH   ******************************/

    if_c_pc_inc = if_pc + 0x4;  // Generate "PC + 0x4" signal
    ic->i_CAdr = if_pc;         // Supply ICACHE with address pointed to by PC
    ic->i_CRE = 1;              // Enable reading from ICACHE

    /*********************************  DECODE  ******************************/

    // Generate signals for all operation types
    id_c_load   = (getOpcode(id_ir) == 0b00000) && ((id_ir & 0b11) == 3);
    id_c_store  = (getOpcode(id_ir) == 0b01000) && ((id_ir & 0b11) == 3);
    id_c_jalr   = (getOpcode(id_ir) == 0b11001) && ((id_ir & 0b11) == 3);
    id_c_jal    = (getOpcode(id_ir) == 0b11011) && ((id_ir & 0b11) == 3);
    id_c_op_imm = (getOpcode(id_ir) == 0b00100) && ((id_ir & 0b11) == 3);
    id_c_op     = (getOpcode(id_ir) == 0b01100) && ((id_ir & 0b11) == 3);
    id_c_auipc  = (getOpcode(id_ir) == 0b00101) && ((id_ir & 0b11) == 3);
    id_c_lui    = (getOpcode(id_ir) == 0b01101) && ((id_ir & 0b11) == 3);
    id_c_branch = (getOpcode(id_ir) == 0b11000) && ((id_ir & 0b11) == 3);

    // Get the immediate value and read from register set
    //  If currently executing lui force rd1 to read from 0
    //  This is needed to ensure that ALU adds immediate to 0
    id_c_imm = getImmediate(id_ir);
    id_c_rd1 = rs.read((id_c_lui) ? 0 : getRs1(id_ir));
    id_c_rd2 = rs.read(getRs2(id_ir));

    // Write back result if WB enabled
    if (wb_c9) rs.write(wb_c8, wb_wb);

    // Determine if current operations can generate data hazards
    //  Only LUI, AUIPC and JAL don't use rs1 so they disable hazard on rs1
    //  Only branches, store and normal arythmetic use rs2, they enable hazard on it
    id_c_h_rs1 = !id_c_lui && !id_c_auipc && !id_c_jal;
    id_c_h_rs2 = id_c_branch || id_c_store || id_c_op;

    // Check if operation if valid 32bit opcode (by checking if bits 1 and 0 are set)
    id_c_op_ok = ((id_ir & 0x3) == 0x3);
    // If operation is valid supply branch conditioner with data
    id_c_c1 = (id_c_op_ok)? ((getFunct3(id_ir) << 5) | getOpcode(id_ir)) : 0;
    // Only normal arythmetic doesn't use immediates an ALU B input
    id_c_c2 = !(id_c_op);
    // Only branches, JAL and AUIPC use ALU to generate address
    id_c_c3 = (id_c_jal | id_c_branch | id_c_auipc);
    // Combine all needed signals to form ALU input opcode
    id_c_c4 = ((id_c_op | id_c_op_imm) << 5) | (!(id_c_op) << 4) | (((id_ir >> 30) & 1) << 3) | getFunct3(id_ir);
    // If operation is store and it's OK enable DCACHE write
    id_c_c5 = (id_c_store && id_c_op_ok) ? ((getFunct3(id_ir) & 0x3) + 1) : 0;
    // If operation is load and it's OK enable DCACHE read
    id_c_c6 = (id_c_load && id_c_op_ok) ? (((getFunct3(id_ir) & 0x3) + 1) + (getFunct3(id_ir) & 0x4)) : 0;
    // Generate a write back select signal
    id_c_c7 = id_c_load; if (id_c_jal || id_c_jalr) id_c_c7 = 2;
    // Get the write back address
    id_c_c8 = getRd(id_ir);
    // Only store and branches don't write back any data
    id_c_c9 = !(id_c_store | id_c_branch) && id_c_op_ok;

    /********************************  EXECUTE   *****************************/

    // Select the correct input data for ALU input A
    ex_c_alu_a = (ex_c3) ? ex_pc  : ex_rd1;
    // Select the correct input data for ALU input B
    ex_c_alu_b = (ex_c2) ? ex_imm : ex_rd2;
    // Perform an ALU operation
    ex_c_alu = alu(ex_c_alu_a, ex_c_alu_b, ex_c4);
    // Use branch conditioner to check if branch should be taken
    ex_c_br_en = branch(ex_rd1, ex_rd2, ex_c1);

    /*****************************  MEMORY ACCESS   **************************/

    
    /****************************  HAZARD DETECTION  *************************/

    // Check for hazard on EX, MEM and WB stages
    bool h1 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == ex_c8) && id_c_h_rs1;
    bool h2 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == ex_c8) && id_c_h_rs2;
    bool h3 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == mem_c8) && id_c_h_rs1;
    bool h4 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == mem_c8) && id_c_h_rs2;
    bool h5 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == wb_c8) && id_c_h_rs1;
    bool h6 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == wb_c8) && id_c_h_rs2;
    bool hz_ex  = h1 || h2;
    bool hz_mem = h3 || h4;
    bool hz_wb  = h5 || h6;
    // Generate data hazard signal if hazard occured on any stage of the pipeline
    hz_dat = hz_ex || hz_mem || hz_wb;

}


/**
 * @brief Second update, stores the results of the combinational calculations to the pipeline registers
 * 
 */
void CentralProcessingUnit::UpdateSequential(void)
{

    /******************************  CLOCK ENABLE  ***************************/

    // Generate clock enable signals for all pipeline stages
    ce_if  = ic->o_CVD && dc->o_CVD && (!hz_dat || ex_c_br_en);
    ce_id  = ic->o_CVD && dc->o_CVD && !hz_dat;
    ce_ex  = ic->o_CVD && dc->o_CVD;
    ce_mem = ic->o_CVD && dc->o_CVD;
    ce_wb  = ic->o_CVD && dc->o_CVD;

    /*******************************  WRITE BACK  ****************************/

    if (ce_wb) 
    { 
        // Generate correct writeback data
        unsigned wb_read_data = readData(mem_alu & 0x3, mem_c6 & 0x3, mem_c6>>2, dc->o_CRDat);
        wb_wb = (mem_c7 >> 1) ? mem_ret : (mem_c7 & 1) ? wb_read_data : mem_alu;
        // Copy control signals from previous stage
        wb_c8 = mem_c8;
        wb_c9 = mem_c9;
    }

    /*****************************  MEMORY ACCESS   **************************/

    if (ce_mem) 
    {
        // Store ALU operation result
        mem_alu = ex_c_alu;

        // Copy signals from previous  stage
        mem_rd2 = ex_rd2;
        mem_ret = ex_ret;
        mem_c5 = ex_c5;
        mem_c6 = ex_c6;
        mem_c7 = ex_c7;
        mem_c8 = ex_c8;
        mem_c9 = ex_c9;

        // Supply DCACHE with necessary signals
        unsigned mem_c_we = (mem_c5>>1)? ((mem_c5&1)? 0xF : 0x3) : ((mem_c5&1)? 0x1 : 0x0);
        mem_c_we = mem_c_we << (mem_alu & 3);
        mem_c_we = mem_c_we & 0xF;
        dc->i_CWE = mem_c_we;

        dc->i_CRE = !!mem_c6;
        if (!!mem_c5 || !!mem_c6) dc->i_CAdr = mem_alu;
        if (!!mem_c5) dc->i_CWDat = writeData(mem_alu & 0x3, mem_c5, mem_rd2);
    }

    /********************************  EXECUTE   *****************************/

    if (ce_ex) 
    {
        // If there weren't any hazards store the combitional signals in registers
        if (!hz_dat && !hz_br) 
        {
            ex_rd1 = id_c_rd1;
            ex_rd2 = id_c_rd2;
            ex_imm = id_c_imm;
            ex_pc = id_pc;
            ex_ret = id_ret;
            ex_c1 = id_c_c1;
            ex_c2 = id_c_c2;
            ex_c3 = id_c_c3;
            ex_c4 = id_c_c4;
            ex_c5 = id_c_c5;
            ex_c6 = id_c_c6;
            ex_c7 = id_c_c7;
            ex_c8 = id_c_c8;
            ex_c9 = id_c_c9;
        } 
        // Else fill registers with zeros
        else 
        {
            ex_rd1 = 0;
            ex_rd2 = 0;
            ex_imm = 0;
            ex_pc = 0;
            ex_ret = 0;
            ex_c1 = 0;
            ex_c2 = 0;
            ex_c3 = 0;
            ex_c4 = 0;
            ex_c5 = 0;
            ex_c6 = 0;
            ex_c7 = 0;
            ex_c8 = 0;
            ex_c9 = 0;
        }
    }

    /*********************************  DECODE  ******************************/

    if (ce_id) 
    {
        id_ret = if_c_pc_inc; // Store the return address in register
        id_pc = if_pc;        // Copy the PC from previous stage
        id_ir = ic->o_CRDat;  // Store opcode read from memory in register
    }
    if (ex_c_br_en)           // If branch was taken: 
    {
        id_ir = 0;            // Clear IR in case instruction would somehow get to execution phase
    }

    /*********************************  FETCH   ******************************/

    if (hz_br) hz_br = 0;  // If branch hazard was set clear it
    if (ce_if) 
    {
        
        if (ex_c_br_en) 
        {
            // If branch was taken:
            ex_c1 = 0; ex_c5 = 0; ex_c6 = 0; ex_c9 = 0;  // Prevent next instruction from executing
            if_pc = ex_c_alu;                            // Copy the ALU operation result to PC
            hz_br = 1;                                   // Set the branch hazard flag
            // Data hazard is set to give time to read next instruction from ICACHE
        } 
        else 
        {
            // Else just advance the PC
            if_pc = if_c_pc_inc;
        }
    }

}


/**
 * @brief Decorated logging of the status
 * 
 */
void CentralProcessingUnit::log(void)
{

    Log::logSrc("  IF    ", (ce_if) ? COLOR_GREEN : COLOR_RED);
    Log::log("if_pc: ");
    Log::logHex(if_pc, COLOR_MAGENTA, 8);
    Log::log("\n");

    Log::logSrc("  ID    ", (ce_id) ? COLOR_GREEN : COLOR_RED);
    Log::log("id_ret: ");
    Log::logHex(id_ret, COLOR_MAGENTA, 8);
    Log::log(", id_pc: ");
    Log::logHex(id_pc, COLOR_MAGENTA, 8);
    Log::log(", id_ir: ");
    Log::logHex(id_ir, COLOR_MAGENTA, 8);
    Log::log("\n");

    Log::logSrc("  EX    ", (ce_ex) ? COLOR_GREEN : COLOR_RED);
    Log::log("ex_rd1: ");
    Log::logHex(ex_rd1, COLOR_MAGENTA, 8);
    Log::log(", ex_rd2: ");
    Log::logHex(ex_rd2, COLOR_MAGENTA, 8);
    Log::log(", ex_imm: ");
    Log::logHex(ex_imm, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  EX    ", (ce_ex) ? COLOR_GREEN : COLOR_RED);
    Log::log("ex_pc: ");
    Log::logHex(ex_pc, COLOR_MAGENTA, 8);
    Log::log(", ex_ret: ");
    Log::logHex(ex_ret, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  EX    ", (ce_ex) ? COLOR_GREEN : COLOR_RED);
    Log::log("ex_c1: ");
    Log::logHex(ex_c1, COLOR_MAGENTA, 2);
    Log::log(", ex_c2: ");
    Log::logDec(ex_c2, COLOR_MAGENTA);
    Log::log(", ex_c3: ");
    Log::logDec(ex_c3, COLOR_MAGENTA);
    Log::log(", ex_c4: ");
    Log::logHex(ex_c4, COLOR_MAGENTA, 2);
    Log::log(", ex_c5: ");
    Log::logDec(ex_c5, COLOR_MAGENTA);
    Log::log("\n");
    Log::logSrc("  EX    ", (ce_ex) ? COLOR_GREEN : COLOR_RED);
    Log::log("ex_c6: ");
    Log::logDec(ex_c6, COLOR_MAGENTA);
    Log::log(", ex_c7: ");
    Log::logHex(ex_c7, COLOR_MAGENTA, 1);
    Log::log(", ex_c8: ");
    Log::logDec(ex_c8, COLOR_MAGENTA);
    Log::log(", ex_c9: ");
    Log::logDec(ex_c9, COLOR_MAGENTA);
    Log::log("\n");

    Log::logSrc("  MEM   ", (ce_mem) ? COLOR_GREEN : COLOR_RED);
    Log::log("mem_rd2: ");
    Log::logHex(mem_rd2, COLOR_MAGENTA, 8);
    Log::log(", mem_alu: ");
    Log::logHex(mem_alu, COLOR_MAGENTA, 8);
    Log::log(", mem_ret: ");
    Log::logHex(mem_ret, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  MEM   ", (ce_mem) ? COLOR_GREEN : COLOR_RED);
    Log::log("mem_c5: ");
    Log::logDec(mem_c5, COLOR_MAGENTA);
    Log::log(", mem_c6: ");
    Log::logDec(mem_c6, COLOR_MAGENTA);
    Log::log(", mem_c7: ");
    Log::logHex(mem_c7, COLOR_MAGENTA, 1);
    Log::log(", mem_c8: ");
    Log::logDec(mem_c8, COLOR_MAGENTA);
    Log::log(", mem_c9: ");
    Log::logDec(mem_c9, COLOR_MAGENTA);
    Log::log("\n");

    Log::logSrc("  WB    ", (ce_wb) ? COLOR_GREEN : COLOR_RED);
    Log::log("wb_wb: ");
    Log::logHex(wb_wb, COLOR_MAGENTA, 8);
    Log::log(", wb_c8: ");
    Log::logDec(wb_c8, COLOR_MAGENTA);
    Log::log(", wb_c9: ");
    Log::logDec(wb_c9, COLOR_MAGENTA);
    Log::log("\n");

    if (hz_dat) {
        Log::logSrc(" HAZARD  ", COLOR_RED);
        Log::log("DATA HAZARD", COLOR_RED);
        Log::log("\n");
    }

    if (hz_br) {
        Log::logSrc(" HAZARD  ", COLOR_RED);
        Log::log("BRANCH HAZARD", COLOR_RED);
        Log::log("\n");
    }

    rs.log();

}


/**
 * @brief JSON logging of the status
 * 
 */
void CentralProcessingUnit::logJson(void)
{

    Log::log("\"if_pc\":");   Log::logDec(if_pc);      Log::log(",");

    Log::log("\"id_ret\":");  Log::logDec(id_ret);     Log::log(",");
    Log::log("\"id_pc\":");   Log::logDec(id_pc);      Log::log(",");
    Log::log("\"id_ir\":");   Log::logDec(id_ir);      Log::log(",");

    Log::log("\"ex_rd1\":");  Log::logDec(ex_rd1);     Log::log(",");
    Log::log("\"ex_rd2\":");  Log::logDec(ex_rd2);     Log::log(",");
    Log::log("\"ex_imm\":");  Log::logDec(ex_imm);     Log::log(",");
    Log::log("\"ex_pc\":");   Log::logDec(ex_pc);      Log::log(",");
    Log::log("\"ex_ret\":");  Log::logDec(ex_ret);     Log::log(",");
    Log::log("\"ex_cb\":");   Log::logDec(ex_c_br_en); Log::log(",");
    Log::log("\"ex_c1\":");   Log::logDec(ex_c1);      Log::log(",");
    Log::log("\"ex_c2\":");   Log::logDec(ex_c2);      Log::log(",");
    Log::log("\"ex_c3\":");   Log::logDec(ex_c3);      Log::log(",");
    Log::log("\"ex_c4\":");   Log::logDec(ex_c4);      Log::log(",");
    Log::log("\"ex_c5\":");   Log::logDec(ex_c5);      Log::log(",");
    Log::log("\"ex_c6\":");   Log::logDec(ex_c6);      Log::log(",");
    Log::log("\"ex_c7\":");   Log::logDec(ex_c7);      Log::log(",");
    Log::log("\"ex_c8\":");   Log::logDec(ex_c8);      Log::log(",");
    Log::log("\"ex_c9\":");   Log::logDec(ex_c9);      Log::log(",");

    Log::log("\"mem_rd2\":"); Log::logDec(mem_rd2);    Log::log(",");
    Log::log("\"mem_alu\":"); Log::logDec(mem_alu);    Log::log(",");
    Log::log("\"mem_ret\":"); Log::logDec(mem_ret);    Log::log(",");
    Log::log("\"mem_c5\":");  Log::logDec(mem_c5);     Log::log(",");
    Log::log("\"mem_c6\":");  Log::logDec(mem_c6);     Log::log(",");
    Log::log("\"mem_c7\":");  Log::logDec(mem_c7);     Log::log(",");
    Log::log("\"mem_c8\":");  Log::logDec(mem_c8);     Log::log(",");
    Log::log("\"mem_c9\":");  Log::logDec(mem_c9);     Log::log(",");

    Log::log("\"wb_wb\":");   Log::logDec(wb_wb);      Log::log(",");
    Log::log("\"wb_c8\":");   Log::logDec(wb_c8);      Log::log(",");
    Log::log("\"wb_c9\":");   Log::logDec(wb_c9);      Log::log(",");
 
    Log::log("\"hz_dat\":");  Log::logDec(hz_dat);     Log::log(",");
    Log::log("\"hz_br\":");   Log::logDec(hz_br);      Log::log(",");
    Log::log("\"ce_if\":");   Log::logDec(ce_if);      Log::log(",");
    Log::log("\"ce_id\":");   Log::logDec(ce_id);      Log::log(",");
    Log::log("\"ce_ex\":");   Log::logDec(ce_ex);      Log::log(",");
    Log::log("\"ce_mem\":");  Log::logDec(ce_mem);     Log::log(",");
    Log::log("\"ce_wb\":");   Log::logDec(ce_wb);      Log::log(",");
 
    Log::log("\"i_fetch\":"); Log::logDec(ic->o_CVD);  Log::log(",");
    Log::log("\"d_fetch\":"); Log::logDec(dc->o_CVD);

    rs.logJson();

}
