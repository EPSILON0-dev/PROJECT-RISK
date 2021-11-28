#include "../main/system.h"
#include "../main/arg.h"

int main(int argc, char** argv)
{

    // Parse the arguments
    int argResult = parseArgs(argc, argv);
    if (argResult == 1) { return 0; }
    if (argResult) { return -1; }

    // Let's get started
    if (CPU::start(argv[argc-1])) { return -1; }

    return 0;

}