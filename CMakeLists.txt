cmake_minimum_required(VERSION 2.8)

project(ethsnarks-emscripten)

set(CMAKE_VERBOSE_MAKEFILE on)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/build.emscripten)

set(USE_ASM OFF)
set(WITH_PROCPS OFF)
set(DEBUG ON)
set(WITH_SUPERCOP OFF)
set(OPT_FLAGS "-O3 -s ALLOW_MEMORY_GROWTH=1 -s DISABLE_EXCEPTION_CATCHING=0 ")

set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_SOURCE_DIR}/installroot)

set(BOOST_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/boost_1_67_0)
set(Boost_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/boost_1_67_0)
set(Boost_LIBRARY_DIR ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib)

set(PKG_CONFIG_USE_CMAKE_PREFIX_PATH on)

set(CRYPTO_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib/libcrypto.a)

set(GMP_LIBRARY ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib/libgmp.a)
set(GMP_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/installroot/include)
set(GMP_LIBRARIES ${CMAKE_CURRENT_SOURCE_DIR}/installroot/lib/libgmp.a)
set(GMPXX_LIBRARIES libgmpxx)


add_subdirectory(ethsnarks)

include_directories(SYSTEM ${CMAKE_CURRENT_SOURCE_DIR}/installroot/include)

include_directories(ethsnarks/src)
include_directories(
  ${DEPENDS_DIR}/libsnark
  ${DEPENDS_DIR}/libsnark/depends/libff
  ${DEPENDS_DIR}/libsnark/depends/libfqfft)

set(
CMAKE_CXX_FLAGS
"${CMAKE_CXX_FLAGS} -std=c++11 -Wall -Wextra -Wfatal-errors"
)


add_executable(test_primes test/primes.c)
target_link_libraries(test_primes ${GMP_LIBRARY})


add_executable(test_importexport test/test_importexport.cpp)
target_link_libraries(test_importexport snark)


add_executable(test_emscripten_stuff test/test_emscripten_stuff.cpp)
target_link_libraries(test_emscripten_stuff snark)


#target_link_libraries(test_hashpreimage "-s EXCEPTION_DEBUG=1 -s DEMANGLE_SUPPORT=1 -s DISABLE_EXCEPTION_CATCHING=0 -s ALLOW_MEMORY_GROWTH=1")
