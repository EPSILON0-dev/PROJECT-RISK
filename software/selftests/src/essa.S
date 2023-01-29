# See LICENSE for license details.

#*****************************************************************************
# simple.S
#-----------------------------------------------------------------------------
#
# This is the most basic self checking test. If your simulator does not
# pass thiss then there is little chance that it will pass any of the
# more complicated self checking tests.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

# Tu pisze:
la x1, 0x4000
li x2, 0x12345678
sw x2, 0(x1)
lb x2, 0(x1)
la x1, 0x8010
srli x2, x2, 8
sw x2, 0(x1)
1: j 1b
# Tu juz ma nie pisac:

RVTEST_PASS

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
