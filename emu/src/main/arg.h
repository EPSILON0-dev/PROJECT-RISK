/**
 * @file arg.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Argument parser
 * @date 2021-11-27
 * 
 */

#ifndef ARG_H
#define ARG_H

#include "../common/config.h"
#include "help.h"
#include <string>
#include <cstring>
#include <iostream>


int parseArgs(int argc, char** argv);

#endif