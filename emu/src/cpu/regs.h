/**
 * @file regs.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Register file class
 * @date 2021-10-21
 * 
 */

#ifndef REGS_H
#define REGS_H

#include "../common/config.h"
#include "../common/log.h"


class RegisterSet
{

private:
    unsigned* regs;
public:
    RegisterSet(void);
    unsigned read(unsigned a);
    void write(unsigned a, unsigned d);
    void log(void);
    void logJson(void);
    
};

#endif