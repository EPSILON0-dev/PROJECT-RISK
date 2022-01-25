/**
 * @file system.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main system file
 * @date 2021-11-27
 * 
 */

#ifndef SYSTEM_H
#define SYSTEM_H

#include "../common/log.h"
#include "../cpu/cpu.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"
#include "../memory/fsb.h"
#include "../memory/ddr.h"
#include <fstream>


namespace CPU {
    int start();
    void loop(void);
    unsigned cycle(void);
    unsigned cycleLog(void);
    unsigned cycleLogJson(void);
}

#endif