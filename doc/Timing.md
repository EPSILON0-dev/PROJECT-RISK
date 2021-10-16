# Timings for each instruction group

### Decode Signals

```
wb_enable
wb_src_alu
wb_src_dcache
wb_src_imm
wb_src_ret

mem_load_en
mem_store_en

ex_alu_a_pc
ex_alu_b_reg
ex_br
```

### 00-000: LOAD

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Calculate the address from register and immediate on address adder
MEM: Put the request address on data cache address bus
WB: Copy the data directly from cache input to the register
```

### 01-000: STORE

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Calculate the address from register and immediate on address adder
MEM: Put the request on data cache address and data bus
WB: Do nothing
```

### 11-000: BRANCH

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Check if branch is taken (on combinational conditioner), if the branch is taken change the PC value and make IF, ID and EX instructions invalid
MEM: Do nothing
WB: Do nothing
```

### 11-001: JALR

```
IF: Fetch the opcode
ID: Set the register addresses on RS, store PC value to temp register
EX: Calculate the address from register and immediate on address adder and jump there, make IF, ID and EX instructions invalid
MEM: Do nothing
WB: Store the return value to RS
```

### 11-011: JAL

```
IF: Fetch the opcode
ID: Set the register addresses on RS, store PC value to temp register
EX: Calculate the address from PC value and immediate on address adder and jump there, make IF, ID and EX instructions invalid
MEM: Do nothing
WB: Store the return value to RS 
```

### 00-101: AUIPC

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Calculate the address from PC and immediate and store it in temp ALU register
MEM: Do nothing
WB: Store the value from temp ALU register to RS
```

### 01-101: LUI

```
IF: Fetch the opcode
ID: Do nothing
EX: Do nothing
MEM: Do nothing
WB: Store immediate to RS
```

### 00-110: OP-IMM-32

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Calculate the result
MEM: Do nothing
WB: Store the value to RS
```

### 01-110: OP-32

```
IF: Fetch the opcode
ID: Set the register addresses on RS
EX: Calculate the result
MEM: Do nothing
WB: Store the value to RS
```
