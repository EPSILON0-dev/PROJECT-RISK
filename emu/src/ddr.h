/**
 * This is a file for C++ emulator of the machine
 * 
 */

class MainRam 
{

private:  // Memories and registers
    unsigned* ram;
    
    unsigned activeRow;
    unsigned readAddress;

    enum eState { cIdle, cRow, cRowDelay, cRead, cCL1, cCL2, cReading };
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
    unsigned i_ReadAddress;
    bool i_ReadRequest;


private:  // Internal versions of output ports
    unsigned n_CacheWriteAddress;
    unsigned n_CacheWriteData;
    bool n_CacheLastWrite;
    bool n_CacheWriteEnable;
    bool n_ReadAck;


public:  // Output ports
    unsigned o_CacheWriteAddress;
    unsigned o_CacheWriteData;
    bool o_CacheLastWrite;
    bool o_CacheWriteEnable;
    bool o_ReadAck;


public:  // Update function
    void Update(void);
    void UpdatePorts(void);


public:  // Logging function
    void log(void);

};