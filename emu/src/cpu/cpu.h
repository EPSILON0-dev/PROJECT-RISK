/**
 * @file cpu.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main CPU File
 * @date 2021-10-08
 * 
 */

#ifndef CPU_H
#define CPU_H

#include <iostream>
#include "alu.h"
#include "branch.h"
#include "decode.h"
#include "regs.h"
#include "mem.h"
#include "../common/config.h"
#include "../common/log.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"


class CentralProcessingUnit
{

public:
    bool i_Reset;
    void loadPointers(void* icache, void* dcache);
    void UpdateCombinational(void);
    void UpdateSequential(void);
    void log(void);
    void logJson(void);
    
};

#endif