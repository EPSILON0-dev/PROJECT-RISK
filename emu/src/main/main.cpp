#include "../common/log.h"
#include "../main/system.h"
#include <fstream>

int main(int argc, char** argv)
{

    if (argc != 2) {
        Log::log("File not supplied\n");
        return -1;
    }

    // Let's get started
    if (CPU::start(argv[1])) {
        return -1;
    }

    for (unsigned i = 0; i < 256; i++) {
        CPU::cycleLog();
    }


}