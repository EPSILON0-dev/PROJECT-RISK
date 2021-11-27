#pragma once
#include <string>

namespace Log 
{
    void log(const char* str);
    void log(const char* str, const char* color);
    void log(std::string str);
    void log(std::string str, const char* color);
    void logSrc(const char* str);
    void logSrc(const char* str, const char* color);
    void logHex(unsigned val, unsigned char length = 2, bool prefix = true);
    void logHex(unsigned val, const char* color, unsigned char length = 2, bool prefix = true);
    void logDec(unsigned val);
    void logDec(unsigned val, const char* color);
}