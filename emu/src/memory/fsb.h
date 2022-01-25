/**
 * @file fsb.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Front Side Bus
 * @version 0.7
 * @date 2021-09-19
 * 
 */


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