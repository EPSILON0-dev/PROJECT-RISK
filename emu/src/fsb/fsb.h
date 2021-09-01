/**
 * This is a file for C++ emulator of the machine
 * 
 */

class FrontSideBus
{
private:
    unsigned* readRequestAddress;
    bool* readRequest;

    unsigned* writeQueueAddress;
    bool* writeQueue;
    char writeQueuePtr;

public:
    FrontSideBus(void);
    ~FrontSideBus(void);

public:
    enum eStatus { cComplete, cAwaiting, cQueueFull, cLowerPriority };
    char writeQueueStatus;
    char* readRequestStatus;

public:
    void Update(void);

public:
    void callWrite(unsigned blockAddress);
    void callRead(unsigned blockAddress, unsigned char callerId);
};