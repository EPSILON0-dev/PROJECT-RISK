/**
 * DATA CACHE
 * 
 */

class DataCache
{

private:  // Internal memories and registers
    unsigned* caches1;
    unsigned short* tags1;
    unsigned char* valid1;
    unsigned char* queued1;
    
    unsigned* caches2;
    unsigned short* tags2;
    unsigned char* valid2;
    unsigned char* queued2;

    unsigned* writeAddressQueue;
    unsigned queuePointer;

    unsigned char* lastSet;  // 1 - second set, 0 - first set
    bool fetchSet;           // 1 - second set, 0 - first set


public:  // Input ports
    unsigned i_CacheAddress;
    unsigned i_CacheWriteData;
    bool i_CacheWriteEnable;
    bool i_CacheReadEnable;

    unsigned i_FsbAddress;
    unsigned i_FsbWriteData;
    bool i_FsbReadAck;
    bool i_FsbWriteEnable;
    bool i_FsbFetchFinished;


private:  // Internal versions of output ports
    unsigned n_CacheReadData;
    bool n_CacheValidData;
    bool n_CacheFetching;

    unsigned n_FsbReadAddress;
    unsigned n_FsbReadRequest;


public:  // Output ports
    unsigned o_CacheReadData;
    bool o_CacheValidData;
    bool o_CacheFetching;

    unsigned o_FsbReadAddress;
    unsigned o_FsbReadRequest;


public:  // Constructor and destructor
    DataCache(void);
    ~DataCache(void);


private:  // Private functions for internal usage
    unsigned getBlock(unsigned a);
    unsigned getIndex(unsigned a);
    unsigned getTag(unsigned a);
    bool checkCache1(unsigned a);
    bool checkCache2(unsigned a);


public:  // Update function
    void Update(void);
    void UpdatePorts(void);


public:  // Logging functions
    void log(void);

};
