/**
 * FRONT SIDE BUS
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

};