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
#include "mem.h"
#include "../common/config.h"
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"

RegisterSet rs;
InstructionCache* ic;
DataCache* dc;

unsigned if_pc = 0;

unsigned id_ret = 0;
unsigned id_pc = 0;
unsigned id_ir = 0;

unsigned ex_rd1 = 0;
unsigned ex_rd2 = 0;
unsigned ex_imm = 0;
unsigned ex_pc = 0;
unsigned ex_ret = 0;
unsigned ex_c1 = 0;
unsigned ex_c2 = 0;
unsigned ex_c3 = 0;
unsigned ex_c4 = 0;
unsigned ex_c5 = 0;
unsigned ex_c6 = 0;
unsigned ex_c7 = 0;
unsigned ex_c8 = 0;
unsigned ex_c9 = 0;

unsigned mem_rd2 = 0;
unsigned mem_alu = 0;
unsigned mem_ret = 0;
unsigned mem_c5 = 0;
unsigned mem_c6 = 0;
unsigned mem_c7 = 0;
unsigned mem_c8 = 0;
unsigned mem_c9 = 0;

unsigned wb_wb = 0;
unsigned wb_c8 = 0;
unsigned wb_c9 = 0;

unsigned if_c_pc_inc = 0;

unsigned id_c_imm = 0;
unsigned id_c_rd1 = 0;
unsigned id_c_rd2 = 0;

bool id_c_load = 0;
bool id_c_store = 0;
bool id_c_jalr = 0;
bool id_c_jal = 0;
bool id_c_op_imm = 0;
bool id_c_op = 0;
bool id_c_auipc = 0;
bool id_c_lui = 0;
bool id_c_branch = 0;
bool id_c_h_rs1 = 0;
bool id_c_h_rs2 = 0;

unsigned id_c_op_ok = 0;
unsigned id_c_c1 = 0;
unsigned id_c_c2 = 0;
unsigned id_c_c3 = 0;
unsigned id_c_c4 = 0;
unsigned id_c_c5 = 0;
unsigned id_c_c6 = 0;
unsigned id_c_c7 = 0;
unsigned id_c_c8 = 0;
unsigned id_c_c9 = 0;

unsigned ex_c_alu_a = 0;
unsigned ex_c_alu_b = 0;
unsigned ex_c_alu = 0;
unsigned ex_c_br_en = 0;

bool hz_ex = 0;
bool hz_mem = 0;
bool hz_wb = 0;
bool hz_br = 0;
bool hz_hazard = 0;

bool ce_if  = 0;
bool ce_id  = 0;
bool ce_ex  = 0;
bool ce_mem = 0;
bool ce_wb  = 0;

void CentralProcessingUnit::loadPointers(void* icache, void* dcache)
{
    ic = (InstructionCache*)icache;
    dc = (DataCache*)dcache;
}

void CentralProcessingUnit::UpdateCombinational(void)
{
    
    /* FETCH */
    if_c_pc_inc = if_pc + 0x4;
    ic->i_CAdr = if_pc;
    ic->i_CRE = 1;

    /* DECODE */
    id_c_imm = getImmediate(id_ir);
    id_c_rd1 = rs.read(getRs1(id_ir));
    id_c_rd2 = rs.read(getRs2(id_ir));

    if (wb_c9) {
        rs.write(wb_c8, wb_wb);
    }

    id_c_load   = (getOpcode(id_ir) == 0b00000) && ((id_ir & 0b11) == 3);
    id_c_store  = (getOpcode(id_ir) == 0b01000) && ((id_ir & 0b11) == 3);
    id_c_jalr   = (getOpcode(id_ir) == 0b11001) && ((id_ir & 0b11) == 3);
    id_c_jal    = (getOpcode(id_ir) == 0b11011) && ((id_ir & 0b11) == 3);
    id_c_op_imm = (getOpcode(id_ir) == 0b00100) && ((id_ir & 0b11) == 3);
    id_c_op     = (getOpcode(id_ir) == 0b01100) && ((id_ir & 0b11) == 3);
    id_c_auipc  = (getOpcode(id_ir) == 0b00101) && ((id_ir & 0b11) == 3);
    id_c_lui    = (getOpcode(id_ir) == 0b01101) && ((id_ir & 0b11) == 3);
    id_c_branch = (getOpcode(id_ir) == 0b11000) && ((id_ir & 0b11) == 3);

    id_c_h_rs1 = !id_c_lui && !id_c_auipc && !id_c_jal;
    id_c_h_rs2 = id_c_branch || id_c_store || id_c_op;

    id_c_op_ok = ((id_ir & 0x3) == 0x3);
    id_c_c1 = (id_c_op_ok)? ((getFunct3(id_ir) << 5) | getOpcode(id_ir)) : 0;
    id_c_c2 = !(id_c_op);
    id_c_c3 = (id_c_jal | id_c_branch);
    id_c_c4 = ((id_c_op | id_c_op_imm) << 5) | (!(id_c_op) << 4) | 
        (((id_ir >> 30) & 1) << 3) | getFunct3(id_ir);
    id_c_c5 = id_c_store && id_c_op_ok;
    id_c_c6 = id_c_load && id_c_op_ok;
    id_c_c7 = id_c_load;
    if (id_c_jal || id_c_jalr) id_c_c7 = 2;
    id_c_c8 = getRd(id_ir);
    id_c_c9 = !(id_c_store | id_c_branch) && id_c_op_ok;

    /* EXECUTE */
    ex_c_alu_a = (ex_c3) ? ex_pc  : ex_rd1;
    ex_c_alu_b = (ex_c2) ? ex_imm : ex_rd2;
    ex_c_alu = alu(ex_c_alu_a, ex_c_alu_b, ex_c4);
    ex_c_br_en = branch(ex_rd1, ex_rd2, ex_c1);

    /* HAZARD DETECTION */
    bool h1 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == ex_c8) && id_c_h_rs1;
    bool h2 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == ex_c8) && id_c_h_rs2;
    bool h3 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == mem_c8) && id_c_h_rs1;
    bool h4 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == mem_c8) && id_c_h_rs2;
    bool h5 = (getRs1(id_ir) != 0) && (getRs1(id_ir) == wb_c8) && id_c_h_rs1;
    bool h6 = (getRs2(id_ir) != 0) && (getRs2(id_ir) == wb_c8) && id_c_h_rs2;
    hz_ex  = h1 || h2;
    hz_mem = h3 || h4;
    hz_wb  = h5 || h6;
    hz_hazard = hz_ex || hz_mem || hz_wb;

}

void CentralProcessingUnit::UpdateSequential(void)
{

    ce_if  = ic->o_CVD && dc->o_CacheValidData && !hz_hazard;
    ce_id  = ic->o_CVD && dc->o_CacheValidData && !hz_hazard;
    ce_ex  = ic->o_CVD && dc->o_CacheValidData;
    ce_mem = ic->o_CVD && dc->o_CacheValidData;
    ce_wb  = ic->o_CVD && dc->o_CacheValidData;

    /* WRITE BACK */
    if (ce_wb) { 
        wb_wb = (mem_c7 >> 1) ? mem_ret : 
            (mem_c7 & 1) ? dc->o_CacheReadData : mem_alu;

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

        dc->i_CacheWriteEnable = mem_c5;
        dc->i_CacheReadEnable = mem_c6;
        if (mem_c5 || mem_c6) dc->i_CacheAddress = mem_alu;
        if (mem_c5) dc->i_CacheWriteData = mem_rd2;
    }

    /* EXECUTE */
    if (ce_ex) {
        if (!hz_hazard && !hz_br) {
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
        } else {
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

    /* DECODE */
    if (ce_id) {
        id_ret = if_c_pc_inc;
        id_pc = if_pc;
        id_ir = ic->o_CRDat;
    }

    /* FETCH */
    if (hz_br) hz_br = 0;
    if (ce_if) {
        if (ex_c_br_en) {
            ex_c1 = 0;
            ex_c5 = 0;
            ex_c6 = 0;
            ex_c9 = 0;
            if_pc = ex_c_alu;
            hz_br = 1;
        } else {
            if_pc = if_c_pc_inc;
        }
    }

}

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

    if (hz_hazard) {
        Log::logSrc(" HAZARD  ", COLOR_RED);
        Log::log("HAZARD DETECTED", COLOR_RED);
        Log::log("\n");
    }

    rs.log();
}
