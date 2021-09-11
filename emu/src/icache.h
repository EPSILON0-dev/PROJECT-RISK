/**
 * This is a file for C++ emulator of the machine
 * 
 */

class InstructionCache
{
private:
    // Set 1
    unsigned* memoryArraySet1;
    unsigned short* tagArraySet1;
    unsigned char* validArraySet1;
    unsigned char* lastAccessedArraySet1;
    // Set 2
    unsigned* memoryArraySet2;
    unsigned short* tagArraySet2;
    unsigned char* validArraySet2;
    unsigned char* lastAccessedArraySet2;

public:
    InstructionCache(void);
    ~InstructionCache(void);

public:
    enum eCacheStatus { cOk, cWait };
    char cacheStatus;

public:
    unsigned read(unsigned address);

public:
    void fsbWriteCache(unsigned address, unsigned data, bool secondSet);
};