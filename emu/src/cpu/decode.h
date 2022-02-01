/**
 * @file branch.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Instruction decoder
 * @date 2021-10-03
 *
 */

#ifndef DECODE_H
#define DECODE_H

#include <string>
#include "../common/config.h"
#include "../common/log.h"


unsigned getFormat(unsigned op);
unsigned getImmediate(unsigned op);
unsigned getRs1(unsigned op);
unsigned getRs2(unsigned op);
unsigned getRd(unsigned op);
unsigned getOpcode(unsigned op);
unsigned getFunct3(unsigned op);

#endif
