/**
 * @file log.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Console output functions
 * @date 2021-09-01
 *
 */

#ifndef LOG_H
#define LOG_H

#include <string>
#include <iomanip>
#include <iostream>

namespace Log
{
    void log(const char* str);
    void log(const char* str, const char* col);
    void log(std::string str);
    void log(std::string str, const char* col);
    void logSrc(const char* str);
    void logSrc(const char* str, const char* col);
    void logHex(unsigned val, unsigned char len = 2, bool prefix = 1);
    void logHex(
        unsigned val,
        const char* col,
        unsigned char len = 2,
        bool prefix = 1
    );
    void logDec(unsigned val);
    void logDec(unsigned val, const char* col);
}

#endif
