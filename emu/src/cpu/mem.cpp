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

    if (s) {
        unsigned char w3 = (d >> 24) & 0xFF;
        unsigned char w2 = (d >> 16) & 0xFF;
        unsigned char w1 = (d >> 8)  & 0xFF;
        unsigned char w0 = d & 0xFF;

        switch (s & 3) {
            case 1: return (w2<<24) || (w1<<16) || (w0<<8) || (w3);
            case 2: return (w1<<24) || (w0<<16) || (w3<<8) || (w2);
            case 3: return (w0<<24) || (w3<<16) || (w2<<8) || (w1);
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
    d = (l)? ((l&1)? d : (d&0xFFFF)) : (d&0xFF);
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
    d = shift(s, d);

    if (u) {
        goto ret;
    } else {
        // Sign extend
        switch (l) {
            case 0: if (d&(1<<7))  return d & 0xFFFFFF00;
            case 1: if (d&(1<<15)) return d & 0xFFFF0000;
        }
    }

    // Return shortened
    ret:
    return (l)? ((l&1)? d : (d&0xFFFF)) : (d&0xFF);;
}