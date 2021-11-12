/**
 * TOP CPU BLOCK
 * 
 */



class CentralProcessingUnit
{

public:
    bool i_Reset;
    void loadPointers(void* icache, void* dcache);
    void UpdateCombinational(void);
    void UpdateSequential(void);
    void log(void);
    
};