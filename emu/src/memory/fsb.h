/**
 * @file fsb.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Front Side Bus
 * @version 0.7
 * @date 2021-09-19
 * 
 */

#ifndef FSB_H
#define FSB_H

#include <random>
#include "../common/config.h"
#include "../common/log.h"
#include "icache.h"
#include "dcache.h"
#include "ddr.h"


class FrontSideBus
{

private:
    unsigned reqAdr;
    char req;
    enum eRequest { cNone, cDCache, cICache, cDWrite };
public:
    FrontSideBus(void);
public:
    void loadPointers(void* instructionCache, void* dataCache, void* mainRam);
public:
    void Update(void);
public:
    void log(void);
    void logJson(void);

};

#endif
