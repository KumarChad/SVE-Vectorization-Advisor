cmake_minimum_required(VERSION 3.13)
project(sve-vectorize-hint)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")

list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(${LLVM_CMAKE_DIR}/AddLLVM.cmake)

add_definitions(${LLVM_DEFINITIONS})
include_directories(${LLVM_INCLUDE_DIRS})

add_library(SveVectorizeHint MODULE src/pass/SveVectorizeHint.cpp)

# Don't link LLVM libraries into the plugin: the host `opt`/`clang`
# binary already provides every LLVM symbol when it dlopen()s us, and
# linking a second copy causes duplicate-registration crashes.
