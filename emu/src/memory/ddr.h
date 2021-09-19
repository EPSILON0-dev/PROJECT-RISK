/**
 * This is a file for C++ emulator of the machine
 * 
 */

class MainRam 
{

private:  // Memories and registers
    unsigned* ram;
    
    unsigned activeRow;
    unsigned address;
    char currentOperation;
    enum eOperation { read, write };

    enum eState { cIdle, cRow, cRowDelay, cRead, cWrite, cCL1, cCL2, cReading, cWriting };
    unsigned state;
    unsigned wordIndex;


public:  // Constructor and destructor
    MainRam(void);
    ~MainRam(void);


private:  // Private functions for internal usage
    unsigned getBank(unsigned a);
    unsigned getRow(unsigned a);
    unsigned getColumn(unsigned a);


public:  // Input ports
    unsigned i_CacheReadData;
    
    unsigned i_Address;
    bool i_ReadRequest;
    bool i_WriteRequest;


private:  // Internal versions of output ports
    unsigned n_CacheAddress;
    unsigned n_CacheWriteData;
    bool n_CacheWriteEnable;
    bool n_CacheReadEnable;
    bool n_CacheLastAccess;

    bool n_ReadAck;
    bool n_WriteAck;


public:  // Output ports
    unsigned o_CacheAddress;
    unsigned o_CacheWriteData;
    bool o_CacheWriteEnable;
    bool o_CacheReadEnable;
    bool o_CacheLastAccess;

    bool o_ReadAck;
    bool o_WriteAck;


public:  // Update function
    void Update(void);
    void UpdatePorts(void);


public:  // Logging function
    void log(void);

};