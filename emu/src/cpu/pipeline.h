/**
 * INSTRUCTION PIPELINE
 * 
 */



class InstructionPipeline 
{

private:  // Memories and registers


public:  // Constructor and destructor
    InstructionPipeline(void) {}
    ~InstructionPipeline(void) {}


public:  // Public enums
    enum eFormat { FormatR, FormatI, FormatS, FormatB, FormatU, FormatJ };


public:  // Input ports
    bool i_ClockEnable;
    bool i_Reset;

    unsigned i_InstructionInput;
    unsigned i_InstructionAddress;


public:  // Internal versions of output ports
    unsigned n_FetchOpcode;
    unsigned n_FetchAddress;
    unsigned n_FetchImmediate;
    unsigned n_FetchFormat;
    bool n_FetchValid;

    unsigned n_DecodeOpcode;
    unsigned n_DecodeAddress;
    unsigned n_DecodeImmediate;
    unsigned n_DecodeFormat;
    bool n_DecodeValid;

    unsigned n_ExecuteOpcode;
    unsigned n_ExecuteAddress;
    unsigned n_ExecuteImmediate;
    unsigned n_ExecuteFormat;
    bool n_ExecuteValid;

    unsigned n_MemoryAccessOpcode;
    unsigned n_MemoryAccessAddress;
    unsigned n_MemoryAccessImmediate;
    unsigned n_MemoryAccessFormat;
    bool n_MemoryAccessValid;

    unsigned n_WriteBackOpcode;
    unsigned n_WriteBackAddress;
    unsigned n_WriteBackImmediate;
    unsigned n_WriteBackFormat;
    bool n_WriteBackValid;


public:  // Output ports
    unsigned o_FetchOpcode;
    unsigned o_FetchAddress;
    unsigned o_FetchImmediate;
    unsigned o_FetchFormat;
    bool o_FetchValid;

    unsigned o_DecodeOpcode;
    unsigned o_DecodeAddress;
    unsigned o_DecodeImmediate;
    unsigned o_DecodeFormat;
    bool o_DecodeValid;

    unsigned o_ExecuteOpcode;
    unsigned o_ExecuteAddress;
    unsigned o_ExecuteImmediate;
    unsigned o_ExecuteFormat;
    bool o_ExecuteValid;

    unsigned o_MemoryAccessOpcode;
    unsigned o_MemoryAccessAddress;
    unsigned o_MemoryAccessImmediate;
    unsigned o_MemoryAccessFormat;
    bool o_MemoryAccessValid;

    unsigned o_WriteBackOpcode;
    unsigned o_WriteBackAddress;
    unsigned o_WriteBackImmediate;
    unsigned o_WriteBackFormat;
    bool o_WriteBackValid;


private:  // Internal functions
    unsigned getFormat(unsigned op);
    unsigned getImmediate(unsigned op);
    unsigned getMnemonic(unsigned op);


public:  // Update functions
    void Update(void);
    void UpdatePorts(void);


public:  // Log functions
    void log(void);

};