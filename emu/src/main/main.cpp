#include "../common/log.h"
#include "../main/system.h"
#include "../main/arg.h"
#include <fstream>

int main(int argc, char** argv)
{

    // Parse the arguments
    int argResult = parseArgs(argc, argv);
    if (argResult == 1) { return 0; }
    if (argResult) { return -1; }

    // Let's get started
    if (CPU::start(argv[1])) { return -1; }

    return 0;

}