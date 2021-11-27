#include "../common/config.h"
#include <cstring>
#include <iostream>
#include <sstream>


unsigned parseHelp(int argc, char** argv);

bool* args;


/**
 * @brief Parse all switches
 * 
 * @return exit code
 */
int parseArgs(int argc, char** argv) 
{

    if (argc == 1) {
        std::cout << "No arguments given, use " << COLOR_YELLOW << "'-h'" << COLOR_NONE << " for help\n";
        return -1;
    }

    // The array is used for finding unknown arguments, if any of 
    //   the bools stays at 0 it means that this argument is unknown
    args = new bool[argc - 1];
    for (int i = 0; i < argc-1; i++) { args[i] = 0; }

    if (parseHelp(argc, argv)) { return 1; }

    return 0;

}


/**
 * @brief Parse the '-h' switch
 * 
 * @param argc 
 * @param argv 
 * @return Switch found 
 */
unsigned parseHelp(int argc, char** argv) 
{

    for (int i = 1; i <= argc; i++) {
        if (strcmp(argv[i], "-h") || strcmp(argv[i], "--help")) {
            args[i] = 1;
            return 1;
        }
    }

    return 0;

}

