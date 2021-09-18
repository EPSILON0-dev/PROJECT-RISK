/**
 * This is a test for basic cache functionality
 *
 */

#include "ddr.h"
#include "log.h"

MainRam ddr;

void Update()
{
    ddr.log();
    ddr.Update();
    ddr.UpdatePorts();
}

int main()
{

    Log::log("\n");

    ddr.i_ReadAddress = 0x0000000;
    ddr.i_ReadRequest = 1;
    Update(); Update();
    ddr.i_ReadRequest = 0;
    for (unsigned i = 0; i < 20; i++)
        Update();
    Log::log("\n");

    ddr.i_ReadAddress = 0x0008000;
    ddr.i_ReadRequest = 1;
    Update(); Update();
    ddr.i_ReadRequest = 0;
    for (unsigned i = 0; i < 20; i++)
        Update();
    Log::log("\n");

    ddr.i_ReadAddress = 0x000F000;
    ddr.i_ReadRequest = 1;
    Update(); Update();
    ddr.i_ReadRequest = 0;
    for (unsigned i = 0; i < 20; i++)
        Update();
    Log::log("\n");

    ddr.i_ReadAddress = 0x3FFFFE0;
    ddr.i_ReadRequest = 1;
    Update(); Update();
    ddr.i_ReadRequest = 0;
    for (unsigned i = 0; i < 20; i++)
        Update();
    Log::log("\n");

    return 0;
}