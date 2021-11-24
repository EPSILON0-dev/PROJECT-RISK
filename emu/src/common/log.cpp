/**
 * LOGGING FUNCTIONS
 * 
 */

#include <iomanip>
#include <iostream>
#include <string>
#include "log.h"

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
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * @param color color escape sequence
 * 
 */
void Log::log(const char* str, const char* color)
{
    std::cout << color << str << "\x1b[0m";
}

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * 
 */
void Log::log(std::string str)
{
    std::cout << str;
}

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * @param color color escape sequence
 * 
 */
void Log::log(std::string str, const char* color)
{
    std::cout << color << str << "\x1b[0m";
}

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * 
 */
void Log::logSrc(const char* str)
{
    std::cout << "[" << str << "]: ";
}

/**
 * @brief This function logs the given string to stdout (just a fancy std::cout)
 * @param str string
 * @param color color escape sequence
 * 
 */
void Log::logSrc(const char* str, const char* color)
{
    std::cout << "[" << color << str << "\x1b[0m" << "]: ";
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
 * @brief This function logs the given value as hex
 * @param val value
 * @param length length of hex value
 * @param prefix add "0x" prefix
 * @param color color escape sequence
 * 
 */
void Log::logHex(unsigned val, const char* color, unsigned char length, bool prefix)
{
    using namespace std;
    cout << color;
    if (prefix) cout << "0x";
    cout << hex << uppercase << setfill('0') << setw(length) << val << "\x1b[0m";
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

/**
 * @brief This function logs the given value as decimal
 * @param val value
 * @param color color escape sequence
 * 
 */
void Log::logDec(unsigned val, const char* color)
{
    using namespace std;
    cout << color << dec << val << "\x1b[0m";
}