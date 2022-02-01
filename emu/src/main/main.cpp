/**
 * @file main.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main emulator file
 * @date 2021-11-28
 *
 */


#include "system.h"
#include "arg.h"

int main(int argc, char** argv)
{

    // Parse the arguments
    int argResult = parseArgs(argc, argv);
    if (argResult == 1) { return 0; }
    if (argResult) { return -1; }

    // Let's get started
    if (CPU::start()) { return -1; }

    return 0;

}
