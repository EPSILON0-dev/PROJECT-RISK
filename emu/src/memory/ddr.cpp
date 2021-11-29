/**
 * @file ddr.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief LPDDR memory emulator
 * @version 0.9
 * @date 2021-09-19
 * 
 */


#include "../common/config.h"
#include "../common/log.h"
#include "ddr.h"


enum eOperation { read, write };
enum eState { cIdle, cRow, cRowDel, cRd, cWr, cCL1, cCL2, cRdng, cWrng };
static unsigned getRow(unsigned a) { return (a >> 11) & 0x1FFF; }
static unsigned getCol(unsigned a) { return (a >> 1) & 0x3FF; }


/**
 * @brief Construct the Main Ram object
 * 
 */
MainRam::MainRam(void)
{
    ram = new unsigned[16 * 1024 * 1024];
    for (unsigned i = 0; i < 16 * 1024 * 1024; i++) ram[i] = (i << 2) | 0x55000000;
}


/**
 * @brief Perform a single cycle of operation
 * 
 */
void MainRam::Update(void) 
{
    
    switch (st) {
        case cIdle:
        n_CWE = 0;
        n_CRE = 0;
        n_CLA = 0;
        adr = i_Adr;
        if (i_RRq || i_WRq) {
            st = (row == getRow(adr)) ? (i_RRq)? cRd : cWr : cRow;
            curOp = (i_RRq)? read : write;
        }
        break;

        case cRow:
        row = getRow(adr);
        st = cRowDel;
        break;

        case cRowDel:
        st = (curOp) ? cWr : cRd;
        break;

        case cRd:
        wInx = 0;
        n_RAck = 1;
        st = cCL1;
        break;

        case cWr:
        wInx = 1;
        n_WAck = 1;
        n_CRE = 1;
        n_CAdr = adr;
        st = cWrng;
        break;

        case cCL1:
        st = cCL2;
        break;

        case cCL2:
        st = cRdng;
        break;

        case cRdng:
        n_RAck = 0;
        n_CWE = 1;
        n_CAdr = adr + (wInx << 2);
        n_CWDat = ram[((n_CAdr & 0x3FFFFFF) >> 2)];
        if (++wInx == 8) { st = cIdle; n_CLA = 1; }
        break;

        case cWrng:
        n_WAck = 0;
        n_CAdr = adr + (wInx << 2);
        if (wInx >= 2) { ram[((n_CAdr & 0x3FFFFFF) >> 2) - 2] = i_CRDat; }
        if (++wInx == 8) { n_CLA = 1; }
        if (wInx == 9) { n_CLA = 0; st = cIdle; }
        break;
    }

}


/**
 * @brief Copy the data from internal outputs to output ports
 * 
 */
void MainRam::UpdatePorts(void) 
{
    o_CAdr  = n_CAdr;
    o_CWDat = n_CWDat;
    o_CWE   = n_CWE;
    o_CRE   = n_CRE;
    o_CLA   = n_CLA;
    o_RAck  = n_RAck;
    o_WAck  = n_WAck;
}


/**
 * @brief Log the activity
 * 
 */
void MainRam::log(void)
{
    Log::logSrc("   DDR   ", COLOR_BLUE);
    
    switch (st) {

        case cRow:
        Log::log("Activate row ");
        Log::logHex(getRow(adr), COLOR_MAGENTA, 4);
        Log::log("\n");
        break;

        case cRowDel:
        Log::log("Waiting for activate\n");
        break;

        case cRd:
        Log::log("Reading column ");
        Log::logHex(getCol(adr), COLOR_MAGENTA, 3);
        Log::log("\n");
        break;

        case cWr:
        Log::log("Writing column ");
        Log::logHex(getCol(adr), COLOR_MAGENTA, 3);
        Log::log("\n");
        break;

        case cCL1:
        Log::log("Waiting for read\n");
        break;

        case cCL2:
        Log::log("Waiting for read\n");
        break;

        case cRdng:
        Log::log("Reading word ");
        Log::logDec(wInx);
        Log::log("\n");
        break;

        case cWrng:
        Log::log("Writing word ");
        Log::logDec(wInx - 1);
        Log::log("\n");
        break;

        default:
        Log::log("Idle cycle\n");
        break;

    }

}