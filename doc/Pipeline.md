# Pipeline Structure

## Fetch

- Put out the address on icache address bus
- Copy the current address to if_address
- Increment the address

## Decode

- Copy if_address into id_address
- Decode the address into id_opcode, id_immediate, id_rs1, id_rs2, id_rd 
- Decode id_opcode into control signals for the rest of the system

## Execute

## Memory Access

## Write Back