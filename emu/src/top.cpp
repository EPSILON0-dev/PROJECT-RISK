
#include "common/log.h"
#include "cpu/cpu.h"
#include "memory/icache.h"
#include "memory/dcache.h"
#include "memory/fsb.h"
#include "memory/ddr.h"
#include <fstream>

MainRam ddr;
InstructionCache iCache;
DataCache dCache;
FrontSideBus fsb;
CentralProcessingUnit cpu;

int main(int argc, char** argv)
{

    if (argc != 2) {
        Log::log("File not supplied\n");
        return -1;
    }

    fsb.loadPointers(&iCache, &dCache, &ddr);
    cpu.loadPointers(&iCache, &dCache);

    // Open a file
    std::ifstream ramImage(argv[1]);
    if (ramImage.fail()) {
        Log::log("File does not exist\n");
        return -1;
    }

    // Load the program
    ramImage.read((char*)(ddr.ram), 64 * 1024 * 1024);

    // Close a file
    ramImage.close();

    for (unsigned i = 0; i < 1024; i++) {
        Log::log("[  CYCLE  ]: ");
        Log::logDec(i + 1);
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
    }

    Log::log("\n\nEXIT STATUS:\n");
    cpu.log();

}