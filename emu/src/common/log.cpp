/**
 * @file log.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Console output functions
 * @date 2021-09-01
 *
 */

#include "log.h"


void Log::log(const char* str)
{
    std::cout << str;
}

void Log::log(const char* str, const char* col)
{
    std::cout << col << str << "\x1b[0m";
}

void Log::log(std::string str)
{
    std::cout << str;
}

void Log::log(std::string str, const char* col)
{
    std::cout << col << str << "\x1b[0m";
}

void Log::logSrc(const char* str)
{
    std::cout << "[" << str << "]: ";
}

void Log::logSrc(const char* str, const char* col)
{
    std::cout << "[" << col << str << "\x1b[0m" << "]: ";
}

void Log::logHex(unsigned val, unsigned char len, bool prefix)
{
    using namespace std;
    if (prefix) cout << "0x";
    cout << hex << uppercase << setfill('0') << setw(len) << val;
}

void Log::logHex(unsigned val, const char* col, unsigned char len, bool prefix)
{
    using namespace std;
    cout << col;
    if (prefix) cout << "0x";
    cout << hex << uppercase << setfill('0') << setw(len) << val << "\x1b[0m";
}

void Log::logDec(unsigned val)
{
    using namespace std;
    cout << dec << val;
}

void Log::logDec(unsigned val, const char* col)
{
    using namespace std;
    cout << col << dec << val << "\x1b[0m";
}
