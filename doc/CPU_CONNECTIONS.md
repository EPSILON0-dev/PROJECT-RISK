# Connections in CPU top block

### ALU connections

```
i_InputA <--- rs.o_ReadDataA
i_InputB <--- rs.o_ReadDataB
i_Opcode3 <--- DECODE <--- ip.o_ExecuteOpcode
i_Opcode7 <--- DECODE <--- ip.o_ExecuteOpcode
i_Immediate <--- DECODE <--- ip.o_ExecuteOpcode
```

### Branch Conditioner connections (combinational)

```
i_Opcode <--- ip.o_ExecuteOpcode
i_RegDataA <--- rs.o_ReadDataA
i_RegDataB <--- rs.o_ReadDataB
```

### Program Counter connections

```
i_ClockEnable <--- DECODE <--- CACHES
i_Reset <--- CPU
i_BranchAddress <--- DECODE
i_Branch <--- bc.o_BranchEnable
```

### Instruction Pipeline connections

```
i_ClockEnable <--- DECODE <--- CACHES
i_Reset <--- CPU
i_InstructionOpcode <--- CACHES
i_InstructionAddress <--- pc.o_Address
```

### Register Set connections

```
i_AddressReadA <--- DECODE
i_AddressReadB <--- DECODE
i_AddressWrite <--- DECODE
i_WriteData <--- TODO
i_WriteEnable <--- DECODE
```