/**
 * TOP CPU BLOCK
 * 
 */



class CentralProcessingUnit
{

public:  // Constructor and destructor
    CentralProcessingUnit(void);
    ~CentralProcessingUnit(void) {}


public:  // Load pointers function
    void loadPointers(void* icache, void* dcache);


public:  // Input signals
    bool i_Reset;


public:  // Update function
    void Update(void);


public:  // Log functions
    void log(void);

};