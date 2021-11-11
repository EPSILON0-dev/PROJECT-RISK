/**
 * REGISTER SET
 * 
 */

class RegisterSet
{
private:
    unsigned* regs;
public:
    RegisterSet(void);
    unsigned read(unsigned a);
    void write(unsigned a, unsigned d);
    void log(void);
};