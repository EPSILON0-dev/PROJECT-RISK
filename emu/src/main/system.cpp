#include "../common/log.h"
#include "../cpu/cpu.h"
#include "../memory/icache.h"
#include "../memory/dcache.h"
#include "../memory/fsb.h"
#include "../memory/ddr.h"
#include <fstream>
#include "system.h"


MainRam ddr;
InstructionCache iCache;
DataCache dCache;
FrontSideBus fsb;
CentralProcessingUnit cpu;

extern unsigned if_pc;
unsigned clockCycle = 0;

unsigned cycleLimit = -1;
unsigned killAddress = -1;


/**
 * @brief Initialize the CPU, load pointers and preload the RAM
 * 
 * @param ramFile Name of the RAM image file
 * @return Exit code
 */
int CPU::start(char* ramFile) 
{

    fsb.loadPointers(&iCache, &dCache, &ddr);
    cpu.loadPointers(&iCache, &dCache);

    std::ifstream ramImage(ramFile);
    if (ramImage.fail()) {
        Log::log("File does not exist\n");
        ramImage.close();
        return -1;
    } else {
        ramImage.read((char*)(ddr.ram), 64 * 1024 * 1024);
        ramImage.close();
    }

    CPU::loop();

    return 0;

}


/**
 * @brief Loop until the CPU performs maximum amount of cycles, 
 *   reaches killaddress or executes HALT (1: beqz zero 1)
 * 
 */
void CPU::loop(void) {
    
    for (unsigned i = 0; i < 256; i++) {
        CPU::cycleLog();
    }

}


/**
 * @brief Do a single CPU cycle (without logging)
 * 
 * @return Program counter after finishing the cycle 
 */
unsigned CPU::cycle(void) {

    cpu.UpdateCombinational();

    iCache.Update();
    dCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();

    cpu.UpdateSequential(); 

    return if_pc;

}


/**
 * @brief Do a single CPU cycle (with logging)
 * 
 * @return Program counter after finishing the cycle 
 */
unsigned CPU::cycleLog(void) {

    Log::log("[  CYCLE  ]: ");
    Log::logDec(++clockCycle);
    Log::log("\n\n");

    cpu.UpdateCombinational();

    iCache.log();
    dCache.log();
    ddr.log();
    fsb.log();

    iCache.Update();
    dCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();

    cpu.UpdateSequential(); 

    Log::log("\n");
    cpu.log();       
    Log::log("\n");

    return if_pc;

}