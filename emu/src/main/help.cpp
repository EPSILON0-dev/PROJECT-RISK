/**
 * @file help.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Help message
 * @date 2021-11-28
 * 
 */

#include "help.h"


void printHelp(void) 
{

    std::cout << BANNER;
    std::cout << "\x1b[37;3mDesigned by \x1b[30;4m\x1b[31;1mEPSILON0\x1b[m\n\n\n";
    std::cout << "Usage:\n";
    std::cout << "  " << NAME << " [-parameteres] filename\n\n";
    std::cout << "Parameters:\n";
    std::cout << "  \x1b[1m-h, --help\x1b[m   - Show this message\n";
    std::cout << "  \x1b[1m-l        \x1b[m   - Enable activity logging\n";
    std::cout << "  \x1b[1m-j        \x1b[m   - Log in JSON format (for use with GUI navigator)\n";
    std::cout << "  \x1b[1m-c        \x1b[m   - Kill the emulator after given amount of cycles\n";
    std::cout << "  \x1b[1m-k        \x1b[m   - Kill the emulator after reaching given address\n";
    std::cout << "  \x1b[1m-m        \x1b[m   - Hide memory initialization (first 27 cycles)\n";
    std::cout << "  \x1b[1m-e        \x1b[m   - Show exit status" << std::endl;

}