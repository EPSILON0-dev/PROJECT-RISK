/**
 * INSTRUCTION CACHE
 * 
 */

class InstructionCache
{

private:
    unsigned* cache1;
    unsigned short* tag1;
    unsigned char* valid1;
    unsigned* cache2;
    unsigned short* tag2;
    unsigned char* valid2;
    unsigned char* lastSet;
    bool fetchSet = 0;
public:
    unsigned i_CAdr = 0;
    bool i_CRE = 0;
    unsigned i_FAdr = 0;
    unsigned i_FWDat = 0;
    bool i_FRAck = 0;
    bool i_FWE = 0;
    bool i_FLA = 0;
private:
    unsigned n_CRDat = 0;
    bool n_CVD = 0;
    bool n_CFetch = 0;
    unsigned n_FRAdr = 0;
    unsigned n_FRReq = 0;
public:
    unsigned o_CRDat = 0;
    bool o_CVD = 0;
    bool o_CFetch = 0;
    unsigned o_FRAdr = 0;
    unsigned o_FRReq = 0;
public:
    InstructionCache(void);
private:
    bool checkCache1(unsigned a);
    bool checkCache2(unsigned a);
public:
    void Update(void);
    void UpdatePorts(void);
public:
    void log(void);

};