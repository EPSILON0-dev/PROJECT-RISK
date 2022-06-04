# See LICENSE for license details.

#*****************************************************************************
# csr.S
#-----------------------------------------------------------------------------
#
# Test csr instructions.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  TEST_CASE( 2, x5, 0x12345678, \
    li x5, 0x12345678; \
    csrw 0x200, x5; \
    li x5, 0x00000000; \
    csrr x5, 0x200; \
  )

  TEST_CASE( 3, x5, 0xA, \
    csrwi 0x200, 0xA; \
    li x5, 0x00000000; \
    csrr x5, 0x200; \
  )

  TEST_CASE( 4, x5, 0xFFFFFFFF, \
    li x5, 0xAAAAAAAA; \
    csrw 0x200, x5; \
    li x5, 0x55555555; \
    csrs 0x200, x5; \
    li x5, 0x00000000; \
    csrr x5, 0x200; \
  )

  TEST_CASE( 5, x5, 0x0, \
    li x5, 0x55555555; \
    csrw 0x200, x5; \
    li x5, 0x55555555; \
    csrc 0x200, x5; \
    li x5, 0x00000000; \
    csrr x5, 0x200; \
  )

  TEST_PASSFAIL

RVTEST_CODE_END
