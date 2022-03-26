# See LICENSE for license details.

#*****************************************************************************
# simple.S
#-----------------------------------------------------------------------------
#
# This is the most chache self checking test. If your simulator does not
# pass this then there is little chance that it will work with any real world
# programs.
#

#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

  #-------------------------------------------------------------
  # Basic tests
  #-------------------------------------------------------------

  # Test 2 cache arrays

  TEST_CASE( 2, x4, 0xdeadbeef, \
    li  x1, 0x00022000; \
    li  x2, 0xdeadbeef; \
    sw  x2, 0(x1); \
    lw  x3, 0(x1); \
    li  x1, 0x00026000; \
    sw  x3, 0(x1); \
    lw  x4, 0(x1); \
  )

  # Test 2 indexes within the same tag

  TEST_CASE( 3, x4, 0x33333333, \
    li  x1, 0x00032000; \
    li  x2, 0x11111111; \
    sw  x2, 0x00(x1); \
    lw  x3, 0x00(x1); \
    mv  x4, x3; \
    add x2, x2, x2; \
    sw  x2, 0x20(x1); \
    lw  x3, 0x20(x1); \
    add x4, x4, x3; \
  )

  # Test writes to main array

  TEST_CASE( 4, x8, 0x13121312, \
    li  x6, 0x00042000; \
    li  x7, 0x13121312; \
    li  x8, 0x21152115; \
    sw  x7, 0x00(x6); \
    li  x6, 0x00044000; \
    lw  x7, 0x00(x6); \
    li  x6, 0x00046000; \
    lw  x7, 0x00(x6); \
    li  x6, 0x00042000; \
    lw  x8, 0x00(x6); \
  )

  TEST_CASE( 5, x9, 0x13371337, \
    li  x6, 0x00052000; \
    li  x7, 0x13371337; \
    li  x8, 0x21152115; \
    sw  x7, 0x00(x6); \
    li  x6, 0x00054000; \
    sw  x8, 0x00(x6); \
    li  x6, 0x00056000; \
    sw  x8, 0x00(x6); \
    li  x6, 0x00052000; \
    lw  x9, 0x00(x6); \
  )

  # Test writing back to main array (test all fields in the block)

  TEST_CASE( 6, x4, 0xFFFFFFFF, \
    li   x16, 0x00010001; \
    li   x4, 0x00062000; \
    slli x17, x16, 1; \
    slli x18, x17, 1; \
    slli x19, x18, 1; \
    slli x20, x19, 1; \
    slli x21, x20, 1; \
    slli x22, x21, 1; \
    slli x23, x22, 1; \
    slli x24, x23, 1; \
    slli x25, x24, 1; \
    slli x26, x25, 1; \
    slli x27, x26, 1; \
    slli x28, x27, 1; \
    slli x29, x28, 1; \
    slli x30, x29, 1; \
    slli x31, x30, 1; \
    \
    sw   x16, 0x00(x4); \
    sw   x17, 0x04(x4); \
    sw   x18, 0x08(x4); \
    sw   x19, 0x0c(x4); \
    sw   x20, 0x10(x4); \
    sw   x21, 0x14(x4); \
    sw   x22, 0x18(x4); \
    sw   x23, 0x1c(x4); \
    sw   x24, 0x20(x4); \
    sw   x25, 0x24(x4); \
    sw   x26, 0x28(x4); \
    sw   x27, 0x2c(x4); \
    sw   x28, 0x30(x4); \
    sw   x29, 0x34(x4); \
    sw   x30, 0x38(x4); \
    sw   x31, 0x3c(x4); \
    \
    li  x4, 0x00064000; \
    lw  x5, 0x00(x4); \
    lw  x5, 0x20(x4); \
    li  x4, 0x00066000; \
    lw  x5, 0x00(x4); \
    lw  x5, 0x20(x4); \
    li  x4, 0x00062000; \
    \
    lw   x31, 0x00(x4); \
    lw   x30, 0x04(x4); \
    lw   x29, 0x08(x4); \
    lw   x28, 0x0c(x4); \
    lw   x27, 0x10(x4); \
    lw   x26, 0x14(x4); \
    lw   x25, 0x18(x4); \
    lw   x24, 0x1c(x4); \
    lw   x23, 0x20(x4); \
    lw   x22, 0x24(x4); \
    lw   x21, 0x28(x4); \
    lw   x20, 0x2c(x4); \
    lw   x19, 0x30(x4); \
    lw   x18, 0x34(x4); \
    lw   x17, 0x38(x4); \
    lw   x16, 0x3c(x4); \
    \
    mv   x4, x16; \
    add  x4, x4, x17; \
    add  x4, x4, x18; \
    add  x4, x4, x19; \
    add  x4, x4, x20; \
    add  x4, x4, x21; \
    add  x4, x4, x22; \
    add  x4, x4, x23; \
    add  x4, x4, x24; \
    add  x4, x4, x25; \
    add  x4, x4, x26; \
    add  x4, x4, x27; \
    add  x4, x4, x28; \
    add  x4, x4, x29; \
    add  x4, x4, x30; \
    add  x4, x4, x31;
  )

TEST_PASSFAIL

RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
