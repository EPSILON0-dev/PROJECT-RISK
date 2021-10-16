/**
 * BRANCH CONDITIONER
 * 
 */

/**
 * @brief Calculate if branch should be taken
 * 
 * @param a Compare register A
 * @param b Compare register B
 * @param o Opcode [7:5]: funct3 [4:0]: opcode[6:2]
 * 
 * @return Branch enable
 */
bool branchCalculate(unsigned a, unsigned b, unsigned o);
