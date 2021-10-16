/**
 * CENTRAL PROCESSING UNIT
 * 
 * 
 */
#include "alu.h"
#include "branch.h"
#include "cpu.h"
#include "decode.h"
#include "regs.h"
#include "../common/config.h"
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"

RegisterSet rs;
InstructionCache* ic;
DataCache* dc;

unsigned if_pc;

unsigned id_ret;
unsigned id_pc;
unsigned id_ir;

unsigned ex_rd1;
unsigned ex_rd2;
unsigned ex_imm;
unsigned ex_pc;
unsigned ex_ret;
unsigned ex_c1;
unsigned ex_c2;
unsigned ex_c3;
unsigned ex_c4;
unsigned ex_c5;
unsigned ex_c6;
unsigned ex_c7;
unsigned ex_c8;
unsigned ex_c9;

unsigned mem_rd2;
unsigned mem_alu;
unsigned mem_ret;
unsigned mem_c5;
unsigned mem_c6;
unsigned mem_c7;
unsigned mem_c8;
unsigned mem_c9;

unsigned wb_wb;
unsigned wb_c8;
unsigned wb_c9;

unsigned if_c_pc_inc;

unsigned id_c_imm;
unsigned id_c_rd1;
unsigned id_c_rd2;

bool id_c_load;
bool id_c_store;
bool id_c_jalr;
bool id_c_jal;
bool id_c_op_imm;
bool id_c_op;
bool id_c_auipc;
bool id_c_lui;
bool id_c_branch;

unsigned id_c_op_ok;
unsigned id_c_c1;
unsigned id_c_c2;
unsigned id_c_c3;
unsigned id_c_c4;
unsigned id_c_c5;
unsigned id_c_c6;
unsigned id_c_c7;
unsigned id_c_c8;
unsigned id_c_c9;

unsigned ex_c_alu_a;
unsigned ex_c_alu_b;
unsigned ex_c_alu;
unsigned ex_c_br_en;

CentralProcessingUnit::CentralProcessingUnit(void)
{
    
}

void CentralProcessingUnit::loadPointers(void* icache, void* dcache)
{
    ic = (InstructionCache*)icache;
    dc = (DataCache*)dcache;
}

void CentralProcessingUnit::UpdateCombinational(void)
{
    
    /* FETCH */
    if_c_pc_inc = if_pc + 0x4;
    ic->i_CacheAddress = if_pc;
    ic->i_CacheReadEnable = 1;

    /* DECODE */
    id_c_imm = getImmediate(id_ir);
    id_c_rd1 = rs.regRead(getRs1(id_ir));
    id_c_rd2 = rs.regRead(getRs2(id_ir));

    if (wb_c9) {
        rs.regWrite(wb_c8, wb_wb);
    }

    id_c_load = (getOpcode(id_ir) == 0b00000);
    id_c_store = (getOpcode(id_ir) == 0b01000);
    id_c_jalr = (getOpcode(id_ir) == 0b11001);
    id_c_jal = (getOpcode(id_ir) == 0b11011);
    id_c_op_imm = (getOpcode(id_ir) == 0b00100);
    id_c_op = (getOpcode(id_ir) == 0b01100);
    id_c_auipc = (getOpcode(id_ir) == 0b00101);
    id_c_lui = (getOpcode(id_ir) == 0b01101);
    id_c_branch = (getOpcode(id_ir) == 0b11000);

    id_c_op_ok = ((id_ir & 0x3) == 0x3);
    id_c_c1 = (id_c_op_ok)? ((getFunct3(id_ir) << 5) | getOpcode(id_ir)) : 0;
    id_c_c2 = !(id_c_op);
    id_c_c3 = (id_c_jal | id_c_branch);
    id_c_c4 = ((id_c_op | id_c_op_imm) << 5) | (!(id_c_op) << 4) | 
        (((id_ir >> 30) & 1) << 3) | getFunct3(id_ir);
    id_c_c5 = id_c_store && id_c_op_ok;
    id_c_c6 = id_c_load && id_c_op_ok;
    id_c_c7 = 0; // TODO
    id_c_c8 = getRd(id_ir);
    id_c_c9 = !(id_c_store | id_c_branch) && id_c_op_ok;

    /* EXECUTE */
    ex_c_alu_a = (ex_c3) ? ex_pc  : ex_rd1;
    ex_c_alu_b = (ex_c2) ? ex_imm : ex_rd2;
    ex_c_alu = aluCalculate(ex_c_alu_a, ex_c_alu_b, ex_c4);
    ex_c_br_en = branchCalculate(ex_rd1, ex_rd2, ex_c1);

    /* MEMORY ACCESS */
    dc->i_CacheWriteEnable = mem_c5;
    dc->i_CacheReadEnable = mem_c6;
    dc->i_CacheAddress = mem_alu;
    dc->i_CacheWriteData = mem_rd2;

}

void CentralProcessingUnit::UpdateSequential(void)
{

    bool ce_if  = ic->o_CacheValidData && dc->o_CacheValidData;
    bool ce_id  = ic->o_CacheValidData && dc->o_CacheValidData;
    bool ce_ex  = ic->o_CacheValidData && dc->o_CacheValidData;
    bool ce_mem = ic->o_CacheValidData && dc->o_CacheValidData;
    bool ce_wb  = ic->o_CacheValidData && dc->o_CacheValidData;

    /* WRITE BACK */
    if (ce_wb) { 
        wb_wb = ((mem_c7 >> 1) & 1) ? (mem_c7 & 1) ? 
            mem_ret : dc->o_CacheReadData : mem_alu;

        wb_c8 = mem_c8;
        wb_c9 = mem_c9;
    }

    /* MEMORY ACCESS */
    if (ce_mem) {
        mem_rd2 = ex_rd2;
        mem_alu = ex_c_alu;
        mem_ret = ex_ret;
        mem_c5 = ex_c5;
        mem_c6 = ex_c6;
        mem_c7 = ex_c7;
        mem_c8 = ex_c8;
        mem_c9 = ex_c9;
    }

    /* EXECUTE */
    if (ce_ex) {
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

    /* DECODE */
    if (ce_id) {
        id_ret = if_c_pc_inc;
        id_pc = if_pc;
        id_ir = ic->o_CacheReadData;
    }

    /* FETCH */
    if (ce_if) {
        if (ex_c_br_en) {
            ex_c1 = 0;
            ex_c5 = 0;
            ex_c6 = 0;
            ex_c9 = 0;
            if_pc = ex_c_alu;
        } else {
            if_pc = if_c_pc_inc;
        }
    }

}

void CentralProcessingUnit::log(void)
{
    Log::logSrc("  IF    ", COLOR_GREEN);
    Log::log("if_pc: ");
    Log::logHex(if_pc, COLOR_MAGENTA, 8);
    Log::log("\n");

    Log::logSrc("  ID    ", COLOR_GREEN);
    Log::log("id_ret: ");
    Log::logHex(id_ret, COLOR_MAGENTA, 8);
    Log::log(", id_pc: ");
    Log::logHex(id_pc, COLOR_MAGENTA, 8);
    Log::log(", id_ir: ");
    Log::logHex(id_ir, COLOR_MAGENTA, 8);
    Log::log("\n");

    Log::logSrc("  EX    ", COLOR_GREEN);
    Log::log("ex_rd1: ");
    Log::logHex(ex_rd1, COLOR_MAGENTA, 8);
    Log::log(", ex_rd2: ");
    Log::logHex(ex_rd2, COLOR_MAGENTA, 8);
    Log::log(", ex_imm: ");
    Log::logHex(ex_imm, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  EX    ", COLOR_GREEN);
    Log::log("ex_pc: ");
    Log::logHex(ex_pc, COLOR_MAGENTA, 8);
    Log::log(", ex_ret: ");
    Log::logHex(ex_ret, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  EX    ", COLOR_GREEN);
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
    Log::logSrc("  EX    ", COLOR_GREEN);
    Log::log("ex_c6: ");
    Log::logDec(ex_c6, COLOR_MAGENTA);
    Log::log(", ex_c7: ");
    Log::logHex(ex_c7, COLOR_MAGENTA, 1);
    Log::log(", ex_c8: ");
    Log::logDec(ex_c8, COLOR_MAGENTA);
    Log::log(", ex_c9: ");
    Log::logDec(ex_c9, COLOR_MAGENTA);
    Log::log("\n");

    Log::logSrc("  MEM   ", COLOR_GREEN);
    Log::log("mem_rd2: ");
    Log::logHex(mem_rd2, COLOR_MAGENTA, 8);
    Log::log(", mem_alu: ");
    Log::logHex(mem_alu, COLOR_MAGENTA, 8);
    Log::log(", mem_ret: ");
    Log::logHex(mem_ret, COLOR_MAGENTA, 8);
    Log::log("\n");
    Log::logSrc("  MEM   ", COLOR_GREEN);
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

    Log::logSrc("  WB    ", COLOR_GREEN);
    Log::log("wb_wb: ");
    Log::logHex(wb_wb, COLOR_MAGENTA, 8);
    Log::log(", wb_c8: ");
    Log::logDec(wb_c8, COLOR_MAGENTA);
    Log::log(", wb_c9: ");
    Log::logDec(wb_c8, COLOR_MAGENTA);
    Log::log("\n");

    rs.log();
}
