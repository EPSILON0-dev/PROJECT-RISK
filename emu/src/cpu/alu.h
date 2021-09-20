/**
 * ARYTHMETIC AND LOGIC UNIT
 * 
 */

class ArythmeticLogicUnit
{

private:  // Memories and registers
    enum eOpCode3 { cADD, cSLL, cSLT, cSLTU, cXOR, cSRL, cOR, cAND };


public:  // Constructor and Destructor
    ArythmeticLogicUnit(void) {}
    ~ArythmeticLogicUnit(void) {}


private:  // Internal functions
    unsigned execute(void);


public:  // Input ports
    unsigned i_InputA;
    unsigned i_InputB;
    unsigned i_OpCode3;
    unsigned i_OpCode7;
    bool i_Immediate;


public:  // Internal versions of output ports
    unsigned n_Output;


public:  // Output ports
    unsigned o_Output;


public:  // Update functions 
    void Update(void);
    void UpdatePorts(void);


public:  // Log function
    void log(void);

};