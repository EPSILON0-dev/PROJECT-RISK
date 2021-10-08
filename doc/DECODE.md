# Decoder functions required by the system

### Store PC to temp register

```
ID opcode = 11-011 or 11-001? 
```

### Store value to RS

```
WB opcode = 01-110 or 00-110 or 01-101 or 00-101 or 11-011 or 11-001 or 00-000?
```

### RS store source

```
ALU temp register: WB opcode = 00-110 or 01-110 or 00-101?
Direct from dcache: WB opcode = 00-000?
PC temp register: WB opcode = 11-001 or 11-011?
Immediate: WB opcode = 01-101?
```

### MEM request write

```
MEM opcode = 01-000?
```

### MEM request read

```
MEM opcode = 00-000?
```

### ALU input B

```
Immediate: 00-110
RS2: 01-110
```

