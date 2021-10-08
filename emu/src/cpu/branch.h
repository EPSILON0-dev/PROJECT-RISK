/**
 * BRANCH CONDITIONER
 * 
 */



class BranchConditioner 
{

public:  // Constructor and destructor
    BranchConditioner(void);
    ~BranchConditioner(void) {}


public:  // Input ports
    unsigned i_OpCode;
    unsigned i_RegDataA;
    unsigned i_RegDataB;


public:  // Output ports
    bool o_BranchEnable;


public:  // Update functions
    void Update(void);
    

public:  // Log functions
    void log(void);
    
};