cmake_minimum_required(VERSION 3.12)

project(LetItBench VERSION 1.0
  DESCRIPTION "Lenient to Errors, Transformations, Irregularities and Turbulence Benchmarks"
  LANGUAGES C)

set(default_build_type "Benchmark")
set(CMAKE_BUILD_TYPE "${default_build_type}" CACHE
  STRING "Benchmark build type" FORCE)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake" ${CMAKE_MODULE_PATH})

include(benchmarks_configuration/MasterConfig.cmake)
