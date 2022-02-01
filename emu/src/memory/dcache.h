/**
 * @file dcache.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Data cache
 * @version 0.8
 * @date 2021-09-19
 *
 */

#ifndef DCACHE_H
#define DCACHE_H

#include "../common/config.h"
#include "../common/log.h"
#include <iostream>


class DataCache
{

private:
    unsigned* cache1;
    unsigned short* tag1;
    unsigned char* valid1;
    unsigned char* queue1;
    unsigned* cache2;
    unsigned short* tag2;
    unsigned char* valid2;
    unsigned char* queue2;
    unsigned* WAdrQueue;
    unsigned queuePtr = 0;
    unsigned char* lastSet;
public:
    unsigned i_CAdr = 0;
    unsigned i_CWE = 0;
    unsigned i_CWDat = 0;
    bool i_CRE = 0;
    unsigned i_FAdr = 0;
    unsigned i_FWDat = 0;
    bool i_FWE = 0;
    bool i_FRE = 0;
    bool i_FLA = 0;
    bool i_FRAck = 0;
    bool i_FWAck = 0;
private:
    unsigned n_CRDat = 0;
    bool n_CVD = 0;
    bool n_CFetch = 0;
    bool n_CWDone = 0;
    unsigned n_FRAdr = 0;
    unsigned n_FWAdr = 0;
    unsigned n_FWDat = 0;
    bool n_FRReq = 0;
    bool n_FWReq = 0;
    bool n_FQFull = 0;
public:
    unsigned o_CRDat = 0;
    bool o_CVD = 0;
    bool o_CFetch = 0;
    bool o_CWDone = 0;
    unsigned o_FRAdr = 0;
    unsigned o_FWAdr = 0;
    unsigned o_FWDat = 0;
    bool o_FRReq = 0;
    bool o_FWReq = 0;
    bool o_FQFull = 0;
public:
    DataCache(void);
private:
    bool checkCache1(unsigned a);
    bool checkCache2(unsigned a);
    void pushWrite(unsigned a);
    unsigned pullWrite(void);
public:
    void Update(void);
    void UpdatePorts(void);
public:
    void log(void);
    void logJson(void);

};

#endif
