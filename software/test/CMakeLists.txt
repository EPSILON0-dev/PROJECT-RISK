cmake_minimum_required(VERSION 3.13)
enable_language(C ASM)

# Project setup
set (_PROJECT_NAME "test")
set (_SOURCE_DIR "src")
set (_TOOLCHAIN_PREFIX "riscv64-elf-")
set (_LINKER_SCRIPT "linker.ld")
project (${_PROJECT_NAME})

# Custom flags for the project
# set (_ARCH_FLAGS    "-march=rv32i -mabi=ilp32")
set (_ARCH_FLAGS    "-march=rv32imc -mabi=ilp32")
set (_WARN_FLAGS    "-Wall -Wextra")
set (_OPT_FLAGS     "-O1 -g -mdiv -mrelax")
set (_DEF_FLAGS     "")
set (_CXX_FLAGS     "-std=c++11")
set (_C_FLAGS       "-std=c11")
set (_ASM_FLAGS     "")
set (_LINK_FLAGS    "-nostartfiles" "-lm" "-lc" "-lgcc")

# Toolchain setup
set (_COMBINED_FLAGS "${_WARN_FLAGS} ${_ARCH_FLAGS} ${_OPT_FLAGS} ${_DEF_FLAGS}")
set (CMAKE_C_FLAGS "${_COMBINED_FLAGS} ${_C_FLAGS}")
set (CMAKE_CXX_FLAGS "${_COMBINED_FLAGS} ${_CXX_FLAGS}")
set (CMAKE_ASM_FLAGS "${_ASM_FLAGS} ${_ARCH_FLAGS}")
set (CMAKE_C_COMPILER ${_TOOLCHAIN_PREFIX}gcc)
set (CMAKE_CXX_COMPILER ${_TOOLCHAIN_PREFIX}g++)
set (CMAKE_ASM_COMPILER ${_TOOLCHAIN_PREFIX}as)
set (CMAKE_OBJDUMP ${_TOOLCHAIN_PREFIX}objdump)
set (CMAKE_OBJCOPY ${_TOOLCHAIN_PREFIX}objcopy)
set (CMAKE_SIZE ${_TOOLCHAIN_PREFIX}size)
add_link_options ("${_LINK_FLAGS}" -T${CMAKE_SOURCE_DIR}/${_LINKER_SCRIPT})

# Gathering the sources
file (GLOB _SOURCES
  ${_SOURCE_DIR}/*.hpp
  ${_SOURCE_DIR}/*.h
  ${_SOURCE_DIR}/*.cpp
  ${_SOURCE_DIR}/*.c
  ${_SOURCE_DIR}/*.S
)

# Create the executable
add_executable(${_PROJECT_NAME} ${_SOURCES})

# Create the objdump and hex binary
add_custom_command(
  TARGET ${PROJECT_NAME}
  POST_BUILD
  COMMAND ${CMAKE_OBJCOPY} ARGS -O binary ${PROJECT_NAME} ${PROJECT_NAME}.hex
)

add_custom_command(
  TARGET ${PROJECT_NAME}
  POST_BUILD
  COMMAND ${CMAKE_OBJDUMP} ARGS -d -S --visualize-jumps=color --disassembler-color=color -h ${PROJECT_NAME} > ${PROJECT_NAME}.dump
)

add_custom_command(
  TARGET ${PROJECT_NAME}
  POST_BUILD
  COMMAND ${CMAKE_SIZE} ARGS -x -G ${PROJECT_NAME}
)
