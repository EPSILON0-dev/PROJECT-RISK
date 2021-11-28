#include "../common/config.h"
#include <iostream>
using namespace std;

void printHelp(void) 
{

    cout << BANNER;
    cout << "\x1b[37;3mDesigned by \x1b[30;4m\x1b[31;1mEPSILON0\x1b[m\n\n\n";
    cout << "Usage:\n";
    cout << "  " << NAME << " [-parameteres] filename\n\n";
    cout << "Parameters:\n";
    cout << "  \x1b[1m-h, --help\x1b[m   - Show this message\n";
    cout << "  \x1b[1m-l        \x1b[m   - Enable activity logging\n";
    cout << "  \x1b[1m-j        \x1b[m   - Log in JSON format (for use with GUI navigator)\n";
    cout << "  \x1b[1m-c        \x1b[m   - Kill the emulator after given amount of cycles\n";
    cout << "  \x1b[1m-k        \x1b[m   - Kill the emulator after reaching given address\n";
    cout << "  \x1b[1m-e        \x1b[m   - Show exit status\n";

}