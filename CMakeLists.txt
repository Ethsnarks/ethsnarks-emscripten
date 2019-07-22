cmake_minimum_required(VERSION 2.8)

project(ethsnarks-emscripten)

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build.emscripten)

set(USE_ASM OFF)
set(WITH_PROCPS OFF)
set(DEBUG OFF)
set(WITH_SUPERCOP OFF)
set(CMAKE_CXX_FLAGS "-fno-rtti -O3 --llvm-lto 1 --std=c++11 -s ALLOW_MEMORY_GROWTH=1")

set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/installroot)

set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH on)

set(GMP_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib/libgmp.a)
set(GMP_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/installroot/include)
set(GMP_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib/libgmp.a)



include_directories(SYSTEM ${CMAKE_CURRENT_SOURCE_DIR}/installroot/include)

add_subdirectory(ethsnarks)



include_directories(ethsnarks/src)
include_directories(
  ${DEPENDS_DIR}/libsnark
  ${DEPENDS_DIR}/libsnark/depends/libff
  ${DEPENDS_DIR}/libfqfft)


add_executable(test_primes test/primes.c)
target_link_libraries(test_primes ${GMP_LIBRARY})


add_executable(test_emscripten_stuff test/test_emscripten_stuff.cpp)
target_link_libraries(test_emscripten_stuff ff)

