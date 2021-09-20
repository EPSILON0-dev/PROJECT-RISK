/**
 * This is a test for basic ALU functionality
 *
 */

#include "../common/log.h"
#include "../cpu/alu.h"

ArythmeticLogicUnit alu;

void Update()
{
    alu.Update();
    alu.UpdatePorts();
    alu.log();
}

int main()
{
    // ADD operations
    alu.i_Immediate = 0;
    alu.i_OpCode3 = 0x0;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x15;
    alu.i_InputB = 0x15;
    Update();
    alu.i_InputA = 0x12345678;
    alu.i_InputB = 0x87654321;
    Update();
    
    // SUB operations
    alu.i_OpCode3 = 0x0;
    alu.i_OpCode7 = 0x20;

    alu.i_InputA = 0x15;
    alu.i_InputB = 0x16;
    Update();
    alu.i_InputA = 0x87654321;
    alu.i_InputB = 0x76543210;
    Update();

    // SLL operations
    alu.i_OpCode3 = 0x1;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x1;
    alu.i_InputB = 0x1F;
    Update();
    alu.i_InputA = 0x55;
    alu.i_InputB = 0x8;
    Update();

    // SLT operations
    alu.i_OpCode3 = 0x2;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x10;
    alu.i_InputB = 0x10;
    Update();
    alu.i_InputA = 0x0;
    alu.i_InputB = 0x8;
    Update();
    alu.i_InputA = 0xFFFFFFFF;
    alu.i_InputB = 0x10;
    Update();
    alu.i_InputA = 0x10;
    alu.i_InputB = 0xFFFFFFFF;
    Update();

    // SLTU operations
    alu.i_OpCode3 = 0x3;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0xFFFFFFFF;
    alu.i_InputB = 0x10;
    Update();
    alu.i_InputA = 0x10;
    alu.i_InputB = 0xFFFFFFFF;
    Update();

    // XOR operations
    alu.i_OpCode3 = 0x4;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x35;
    alu.i_InputB = 0x53;
    Update();
    alu.i_InputA = 0x55AA55AA;
    alu.i_InputB = 0xAA5555AA;
    Update();

    // SRL operations
    alu.i_OpCode3 = 0x5;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0xAA000000;
    alu.i_InputB = 0x8;
    Update();
    alu.i_InputA = 0x40000000;
    alu.i_InputB = 0x1E;
    Update();

    // SRA operations
    alu.i_OpCode3 = 0x5;
    alu.i_OpCode7 = 0x20;

    alu.i_InputA = 0xAA000000;
    alu.i_InputB = 0x8;
    Update();
    alu.i_InputA = 0x40000000;
    alu.i_InputB = 0x1E;
    Update();

    // OR operations
    alu.i_OpCode3 = 0x6;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x35;
    alu.i_InputB = 0x53;
    Update();
    alu.i_InputA = 0x55AA55AA;
    alu.i_InputB = 0xAA5555AA;
    Update();

    // AND operations
    alu.i_OpCode3 = 0x7;
    alu.i_OpCode7 = 0x00;

    alu.i_InputA = 0x35;
    alu.i_InputB = 0x53;
    Update();
    alu.i_InputA = 0x55AA55AA;
    alu.i_InputB = 0xAA5555AA;
    Update();

    return 0;
}