#include "../common/config.h"
#include "help.h"
#include <string>
#include <cstring>
#include <iostream>


unsigned parseValue(char* str);
unsigned parseHelp(int argc, char** argv);
void parseLog(int argc, char** argv);
void parseLogJson(int argc, char** argv);
void parseExit(int argc, char** argv);
void parseCycles(int argc, char** argv);
void parseKill(int argc, char** argv);

bool valueOk = 1;
bool* args;

extern bool enableLog;
extern bool enableJsonLog;
extern bool enableExitStatus;
extern unsigned cycleLimit;
extern unsigned killAddress;


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

    // -h
    if (parseHelp(argc, argv)) { return 1; }
    
    // -l
    parseLog(argc, argv);

    // -j
    parseLogJson(argc, argv);

    // -e
    parseExit(argc, argv);

    // -c
    parseCycles(argc, argv);
    if (!valueOk) {
        std::cout << "Invalid cycles value " << COLOR_YELLOW << "(-c)" << COLOR_NONE << "\n";
        return -1;
    }

    // -k
    parseKill(argc, argv);
    if (!valueOk) {
        std::cout << "Invalid kill address " << COLOR_YELLOW << "(-k)" << COLOR_NONE << "\n";
        return -1;
    }

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

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-h") || !strcmp(argv[i], "--help")) {
            printHelp();
            return 1;
        }
    }

    return 0;

}


/**
 * @brief Parse the '-l' switch
 * 
 * @param argc 
 * @param argv 
 */
void parseLog(int argc, char** argv) 
{

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-l")) {
            args[i] = 1;
            enableLog = 1;
            return;
        }
    }

}


/**
 * @brief Parse the '-j' switch
 * 
 * @param argc 
 * @param argv 
 */
void parseLogJson(int argc, char** argv) 
{

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-j")) {
            args[i] = 1;
            enableJsonLog = 1;
            return;
        }
    }

}


/**
 * @brief Parse the '-e' switch
 * 
 * @param argc 
 * @param argv 
 */
void parseExit(int argc, char** argv) 
{

    for (int i = 1; i < argc; i++) {
        if (!strcmp(argv[i], "-e")) {
            args[i] = 1;
            enableExitStatus = 1;
            return;
        }
    }

}


/**
 * @brief Parse the '-c' switch
 * 
 * @param argc 
 * @param argv 
 */
void parseCycles(int argc, char** argv) 
{

    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-c", 2)) {
            if (!strcmp(argv[i], "-c")) {
                cycleLimit = parseValue(argv[i+1]);
                args[i] = 1;
                return;
            } else {
                cycleLimit = parseValue(argv[i]+2);
                args[i] = 1; args[i+1] = 1;
                return;
            }
        }
    }
    
}


/**
 * @brief Parse the '-k' switch
 * 
 * @param argc 
 * @param argv 
 */
void parseKill(int argc, char** argv) 
{

    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "-k", 2)) {
            if (!strcmp(argv[i], "-k")) {
                killAddress = parseValue(argv[i+1]);
                args[i] = 1;
                return;
            } else {
                killAddress = parseValue(argv[i]+2);
                args[i] = 1; args[i+1] = 1;
                return;
            }
        }
    }
    
}


/**
 * @brief Parses char DEC/HEX/BIN value into unsigned
 * 
 * @param str 
 * @return Value 
 */
unsigned parseValue(char* str) 
{

    try {
        if (str[0] == '0' && (str[1] == 'x' || str[1] == 'X'))
            return std::stoul(str+2, nullptr, 16);
        if (str[0] == '0' && (str[1] == 'b' || str[1] == 'B'))
            return std::stoul(str+2, nullptr, 2);
        return std::stoul(str, nullptr, 10);
    } catch (std::exception const&) {
        valueOk = 0;
        return 0;
    }

}