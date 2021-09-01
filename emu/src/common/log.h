/**
 * This is a file for C++ emulator of the machine
 * 
 */

namespace Log 
{
    void log(char* str);
    void log(const char* str);
    void logHex(unsigned val, unsigned char length = 2, bool prefix = true);
    void logDec(unsigned val);
}