/**
 * PROGRAM COUNTER
 * 
 */



class ProgramCounter 
{

private:  // Memories and registers
    unsigned programCounter;


public:  // Constructor and destructor
    ProgramCounter(void) {}
    ~ProgramCounter(void) {}


public:  // Input ports
    bool i_ClockEnable;
    bool i_Reset;

    unsigned i_BranchAddress;
    bool i_Branch;


public:  // Internal versions of output ports
    unsigned n_Address;


public:  // Output ports
    unsigned o_Address;


public:  // Update functions
    void Update(void);
    void UpdatePorts(void);


public:  // Log functions
    void log(void);

};