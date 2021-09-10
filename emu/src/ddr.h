/**
 * This is a file for C++ emulator of the machine
 * 
 */

class DDR 
{
private:
    unsigned short activeRow = 0xFFFF;
    unsigned* memoryArray;
    unsigned readAddress;
    unsigned readRow;
    unsigned readColumn;
    unsigned readBank;

public:
    DDR(void);
    ~DDR(void);

public:
    enum eFSM { crFsmIdle, crRowActivate, crActivateDelay, crRequest, crCL1, crCL2, crReading };
    char fsm;
    char burstByte;
    enum eStatus { cIdle, cRead, cWrite, cInitializing };
    char status = cInitializing;
    unsigned readData;

private:
    void updateRead(void);

public:
    void Update(void);

public:
    void performRead(unsigned address);
    //void performWrite(unsigned address);
};