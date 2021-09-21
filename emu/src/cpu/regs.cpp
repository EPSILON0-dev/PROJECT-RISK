/**
 * REGISTER SET
 * 
 */
#include "../common/config.h"
#include "../common/log.h"
#include "regs.h"



/**
 * @brief Constructor
 * 
 */
RegisterSet::RegisterSet(void)
{
    registerArray = new unsigned[32];
    for (unsigned i = 0; i < 32; i++)
        registerArray[i] = 0;
}



/**
 * @brief Destructor
 * 
 */
RegisterSet::~RegisterSet(void)
{
    delete[] registerArray;
}



/**
 * @brief Update function for register set
 * 
 */
void RegisterSet::Update(void)
{

    if (i_WriteEnable && i_AddressWrite) {  // Handle writes
        registerArray[i_AddressWrite] = i_WriteData;
    }

    n_ReadDataA = registerArray[i_AddressReadA];
    n_ReadDataB = registerArray[i_AddressReadB];

}



/**
 * @brief Update ports function for register set
 * 
 */
void RegisterSet::UpdatePorts(void)
{
    o_ReadDataA = n_ReadDataA; 
    o_ReadDataB = n_ReadDataB; 
}



/**
 * @brief Log function for register set
 * 
 */
void RegisterSet::log(void)
{
    Log::logSrc("   REG   ", COLOR_GREEN);
    Log::log("Read A [");
    Log::logDec(i_AddressReadA, COLOR_MAGENTA);
    Log::log("]: ");
    Log::logHex(registerArray[i_AddressReadA], COLOR_MAGENTA, 8);

    Log::log(" Read B [");
    Log::logDec(i_AddressReadB, COLOR_MAGENTA);
    Log::log("]: ");
    Log::logHex(registerArray[i_AddressReadB], COLOR_MAGENTA, 8);

    if (i_WriteEnable && i_AddressWrite) {
        Log::log(" Write [");
        Log::logDec(i_AddressWrite, COLOR_MAGENTA);
        Log::log("]: ");
        Log::logHex(i_WriteData, COLOR_MAGENTA, 8);
    }

    Log::log("\n");
}