include(FetchContent)
include(CheckIPOSupported)

set(FDTD_RESILIENCE_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/FDTDResilienceTest")

# Number of execution of one benchmark
# set(FDTDRESILIENCETEST_BATCH_NUM 5)

# FDTD Build Compilation Options

set(FDTD_RESILIENCE_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(FDTD_RESILIENCE_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  FDTD_RESILIENCE
  GIT_REPOSITORY https://github.com/Syllo/fdtd.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/FDTDResilienceTest"
  )

set(FDTD_RESILIENCE_common_arguments
  -q
  )

# Variable benchmark-name benchmark-options
set(1D_s0  1D-s0 -1 -s 0 -i 222222 -x 0.001                -o "${FDTD_RESILIENCE_RESULTS_DIR}/1D-0.dat")
set(2D_s0  2D-s0 -2 -s 0 -i 2200   -x 0.00002  -y 0.00005  -o "${FDTD_RESILIENCE_RESULTS_DIR}/2D-s0.dat")
set(2D_s1  2D-s1 -2 -s 1 -i 1500   -x 0.00003  -y 0.00003  -o "${FDTD_RESILIENCE_RESULTS_DIR}/2D-s1.dat")
set(2D_s2  2D-s2 -2 -s 2 -i 2000   -x 0.00004  -y 0.00004  -o "${FDTD_RESILIENCE_RESULTS_DIR}/2D-s2.dat")
set(3D_s0  3D-s0 -3 -s 0 -i 200    -x 0.000003 -y 0.000003 -o "${FDTD_RESILIENCE_RESULTS_DIR}/3D-s0.dat")
set(3D_s1  3D-s1 -3 -s 1 -i 200    -x 0.000003 -y 0.000003 -o "${FDTD_RESILIENCE_RESULTS_DIR}/3D-s1.dat")

# Benchmarks to run for FDTD

set(FDTD_RESILIENCE_BENCHMARKS
  1D_s0
  2D_s0
  2D_s1
  2D_s2
  3D_s0
  3D_s1
  )

# Register bench targets

set(FDTD_RESILIENCE_BENCHMARKS_TARGET fdtd_resilience-benchmark)

add_custom_target(${FDTD_RESILIENCE_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS FDTD_RESILIENCE_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND FDTD_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${FDTD_RESILIENCE_RESULTS_DIR}"
    COMMAND fdtd ${bench_arguments} ${FDTD_RESILIENCE_common_arguments} 1> "${FDTD_RESILIENCE_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from FDTD: ${bench_name}"
    VERBATIM)
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET} "${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
endforeach()

add_custom_command(OUTPUT "${FDTD_RESILIENCE_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${FDTD_RESILIENCE_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(fdtd_resilience)

# Benchmark results gathering

set(FDTD_RESILIENCE_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/FDTDGathered.dat")
set(FDTD_RESILIENCE_DATA_COLUMN_NAME "Time")
set(FDTD_RESILIENCE_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'")

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${FDTD_RESILIENCE_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${FDTD_RESILIENCE_BENCH_LINK_OPTION})

FetchContent_GetProperties(FDTD_RESILIENCE)
if (NOT fdtd_resilience_POPULATED)
  message(STATUS "Fetching FDTDREsilienceTest repository...")
  FetchContent_Populate(FDTD_RESILIENCE)
  add_subdirectory(${fdtd_resilience_SOURCE_DIR} ${fdtd_resilience_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED FDTDRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(FDTDRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(FDTDRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
