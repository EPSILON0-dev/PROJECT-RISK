/**
 * ARYTHMETIC AND LOGIC UNIT
 * 
 */

/**
 * @brief Do a single operation on ALU, 
 *  if ALU is not enabled (o[5]) simple ADD is performed,
 *  Imm (o[4]) determines if funct7 (o[3]) should change the operation 
 * 
 * @param a Input A
 * @param b Input B
 * @param o Command input [5]: Enable [4]: Imm [3]: funct7 [2:0]: funct3
 * 
 * @return Result of the operation
 */
unsigned aluCalculate(unsigned a, unsigned b, unsigned o);