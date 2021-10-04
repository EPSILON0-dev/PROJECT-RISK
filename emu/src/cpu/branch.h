/**
 * BRANCH CONDITIONER
 * 
 */



class BranchConditioner 
{

public:  // Constructor and destructor
    BranchConditioner(void) {}
    ~BranchConditioner(void) {}


public:  // Input ports
    unsigned i_OpCode;
    unsigned i_RegData1;
    unsigned i_RegData2;


public:  // Internal versions of output ports
    bool n_BranchEnable;


public:  // Output ports
    bool o_BranchEnable;


public:  // Update functions
    void Update(void);
    void UpdatePorts(void);
    

public:  // Log functions
    void log(void);
    
};