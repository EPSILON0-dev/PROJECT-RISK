/**
 * REGISTER SET
 * 
 */



class RegisterSet
{

private:  // Memories and registers
    unsigned* registerArray;


public:  // Constructor and destructor
    RegisterSet(void);
    ~RegisterSet(void);


public:  // Input ports
    unsigned char i_AddressReadA;
    unsigned char i_AddressReadB;
    unsigned char i_AddressWrite;
    unsigned i_WriteData;
    bool i_WriteEnable;
    bool i_ClockEnable;


private:  // Internal versions of output ports
    unsigned n_ReadDataA;
    unsigned n_ReadDataB;


public:  // Output ports
    unsigned o_ReadDataA;
    unsigned o_ReadDataB;


public:  // Update functions
    void Update(void);
    void UpdatePorts(void);


public:  // Log function
    void log(void);
    void logContent(void);

};