/**
 * @file cpu.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Main CPU File
 * @version 0.9
 * @date 2021-10-08
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
    void logJson(void);
    
};