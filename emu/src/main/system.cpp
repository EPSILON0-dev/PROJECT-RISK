/**
 * @file system.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main system file
 * @date 2021-11-27
 * 
 */


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

bool enableLog = 0;
bool enableJsonLog = 0;
bool enableExitStatus = 0;
bool hideMemoryInit = 0;
unsigned cycleLimit = -1;
unsigned killAddress = -1;
char* ramFile;


/**
 * @brief Initialize the CPU, load pointers and preload the RAM
 * 
 * @param ramFile Name of the RAM image file
 * @return Exit code
 */
int CPU::start() 
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
    
    // Get the correct function
    unsigned (*cycleFunction)(void) = &CPU::cycle;
    if (enableLog) cycleFunction = &CPU::cycleLog;
    if (enableLog && enableJsonLog) cycleFunction = &CPU::cycleLogJson;

    // Execute function until killed
    for (unsigned i = 0; i < cycleLimit; i++) {
        if (hideMemoryInit && i < 27) {
            CPU::cycle();
        } else {
            (*cycleFunction)();
        }
        if (if_pc == killAddress) { break; }
    }

    // Show exit code
    if (enableExitStatus) {
        
        if (enableJsonLog) { cpu.logJson(); }
        else { Log::log("\nEXIT STATUS:\n"); cpu.log(); }
    }

}


/**
 * @brief Do a single CPU cycle (without logging)
 * 
 * @return Program counter after finishing the cycle 
 */
unsigned CPU::cycle(void) {

    clockCycle++;

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


/**
 * @brief Do a single CPU cycle (with logging in json format)
 * 
 * @return Program counter after finishing the cycle 
 */
unsigned CPU::cycleLogJson(void) {

    cpu.UpdateCombinational();

    //iCache.log();
    //dCache.log();
    //ddr.log();
    //fsb.log();

    iCache.Update();
    dCache.Update();
    ddr.Update();

    iCache.UpdatePorts();
    dCache.UpdatePorts();
    ddr.UpdatePorts();

    fsb.Update();

    cpu.UpdateSequential(); 

    cpu.logJson();       

    return if_pc;

}