/**
 * This is a file for C++ emulator of the machine
 * 
 */

#include <iomanip>
#include <iostream>
#include "log.h"

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * 
 */
void Log::log(char* str)
{
    std::cout << str;
}

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * 
 */
void Log::log(const char* str)
{
    std::cout << str;
}

/**
 * @brief This function logs the given value as hex
 * @param val value
 * @param length length of hex value
 * @param prefix add "0x" prefix
 * 
 */
void Log::logHex(unsigned val, unsigned char length, bool prefix)
{
    using namespace std;
    if (prefix) cout << "0x";
    cout << hex << uppercase << setfill('0') << setw(length) << val;
}

/**
 * @brief This function logs the given value as decimal
 * @param val value
 * 
 */
void Log::logDec(unsigned val)
{
    using namespace std;
    cout << dec << val;
}