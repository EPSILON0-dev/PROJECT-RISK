/**
 * @file memory.cpp
 * @author EPSILON0-dev (lforenc@wp.pl)
 * @brief Memory read and write functions
 * @date 2021-11-11
 *
 */


#include "mem.h"

/**
 * @brief Shift the d by s octets
 *
 * @param s Shift amount
 * @param d Data
 * @return Shift result
 */
unsigned shift(char s, unsigned d)
{

    if (s)
    {
        switch (s & 3)
        {
            case 1: return d<<8  | d>>24;
            case 2: return d<<16 | d>>16;
            case 3: return d<<24 | d>>8;
        }
    }

    return d;

}


/**
 * @brief Compute write data for memory
 *
 * @param s Shift of the output data
 * @param l Length of the output data
 * @param d Data
 * @return Result of the operation
 */
unsigned writeData(char s, char l, unsigned d)
{
    // Resize the data
    unsigned d1 = (l&1)? (d&0xFF) : 0;
    unsigned d2 = (l&1)? d : (d&0xFFFF);
    d = (l>>1)? d2 : d1;
    return shift(s, d);
}


/**
 * @brief Compute read data from memory
 *
 * @param s Shift of the input data
 * @param l Length of the length data
 * @param u Unsigned extend
 * @param d Data
 * @return Result of the operation
 */
unsigned readData(char s, char l, bool u, unsigned d)
{
    d = shift((4-s) & 0x3, d);
    unsigned d1 = (l&1)? (d&0xFF) : 0;
    unsigned d2 = (l&1)? d : (d&0xFFFF);
    d = (l>>1)? d2 : d1;

    if (!u)
    {
        // Sign extend
        switch (l)
        {
            case 1: if (d&(1<<7))  return d | 0xFFFFFF00; break;
            case 2: if (d&(1<<15)) return d | 0xFFFF0000; break;
            default: return d;
        }
    }

    return d;
}
