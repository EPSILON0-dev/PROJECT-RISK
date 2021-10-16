/**
 * REGISTER SET
 * 
 */

class RegisterSet
{

private:
    unsigned* registerArray;

public:
    RegisterSet(void);
    ~RegisterSet(void);
    
    /**
     * @brief Read from register set
     * 
     * @param a Read address
     * 
     * @return Data from register set
     */
    unsigned regRead(unsigned a);

    /**
     * @brief Write to register set
     * 
     * @param a Write address
     * @param d Write data
     */
    void regWrite(unsigned a, unsigned d);

    /**
     * @brief Print out the contents of the registers 
     * 
     */
    void log(void);

};