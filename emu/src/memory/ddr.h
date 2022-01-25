/**
 * @file ddr.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief LPDDR memory emulator
 * @version 0.9
 * @date 2021-09-19
 * 
 */

#ifndef DDR_H
#define DDR_H

#include "../common/config.h"
#include "../common/log.h"


class MainRam 
{

public:
    unsigned* ram;
private:
    unsigned row = 0;
    unsigned adr = 0;
    char curOp = 0;
    unsigned st = 0;
    unsigned wInx = 0;
public:
    MainRam(void);
public:
    unsigned i_CRDat = 0;
    unsigned i_Adr = 0;
    bool i_RRq = 0;
    bool i_WRq = 0;
private:
    unsigned n_CAdr = 0;
    unsigned n_CWDat = 0;
    bool n_CWE = 0;
    bool n_CRE = 0;
    bool n_CLA = 0;
    bool n_RAck = 0;
    bool n_WAck = 0;
public:
    unsigned o_CAdr = 0;
    unsigned o_CWDat = 0;
    bool o_CWE = 0;
    bool o_CRE = 0;
    bool o_CLA = 0;
    bool o_RAck = 0;
    bool o_WAck = 0;
public:
    void Update(void);
    void UpdatePorts(void);
public:
    void log(void);
    void logJson(void);

};

#endif
