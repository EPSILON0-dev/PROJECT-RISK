/**
 * @file regs.h
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Register file class
 * @version 0.6
 * @date 2021-10-21
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