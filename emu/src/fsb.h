/**
 * This is a file for C++ emulator of the machine
 * 
 */

class FrontSideBus
{
private:
    unsigned* readRequestAddress;
    bool* readRequestSet;
    bool* readRequest;

    unsigned* writeQueueAddress;
    bool* writeQueue;
    char writeQueuePtr;

    char currentRequest;
    enum eSource { cNone, cRead0, cRead1, cRead2, cWrite };

    char state;
    char burstByte;
    enum eState { cIdle, cCas, cRas, cDelay, cRead };

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
    void callRead(unsigned blockAddress, unsigned char callerId, bool secondSet);
};