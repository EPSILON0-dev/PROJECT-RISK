# Core configuration options

## REGS_PASS_THROUGH

Register pass through, creates a route from register write port to register read ports, in case of data hazard we can end hazard one cycle quicker by forwarding the data direcly from write to read ports. This option makes CPU a bit faster with no noticible LUT requirement increase.

## CLEAN_DATA_BUS

Filter signals from CPU data bus when the current memory operation isn't read nor write. Data address and data output are connected to memory logic no matter what is the operation and memory is only enabled on read or write, this causes undefined data to appear on the bus when executing non-memory operation. Filtering this makes debugging a bit easier but this data is ignored by the memory anyway so this option should be disabled for synthesis.

## CSR_EXTENSION

Enable CSR extension, for now it only enables read/write logic and not much more. In the future there will be more configuration options for these registers.

## CSR_EXTERNAL_BUS

Route CSR data bus out of the CPU this will allow for connecting external registers to CPU's CSR data bus.
  Requires CSR_EXTENSION.

## BARREL_SHIFTER

By default ALU uses bit-shifter which shifts one bit at a time (which is pretty slow), this option replaces bit-shifer with a barrel shifter which shifts everything at once. This of course comes with higher LUT requirements.

## MULDIV_EXTENSION

Enables extesion for hardware multiplication and division.

## FAST_MULTIPLIER

By default a slow multiplier is used which multiplies one bit at a time (something like a bit-shifter but for multiply), this option replaces bit-shifted multiplier with combinational multiplier which does everything at once. This of course comes with higher LUT requirements.
  Requires MULDIV_EXTENSION.
