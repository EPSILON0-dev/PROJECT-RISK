/**
 * This is a file for C++ emulator of the machine
 * 
 */

class FrontSideBus
{

private:  // Internal memories and registers
    unsigned requestAddress;
    char request;
    enum eRequest { cNone, cDCache, cICache, cDWrite };


public:  // Constructor and destructor 
    FrontSideBus(void);
    ~FrontSideBus(void);


public:  // Initialization function
    void loadPointers(void* instructionCache, void* dataCache, void* mainRam);


public:  // Update function for front side bus
    void Update(void);


public:  // Logging functions
    void log(void);

};