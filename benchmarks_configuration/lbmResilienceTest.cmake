include(FetchContent)
include(CheckIPOSupported)

set(LBM_RESILIENCE_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/LBMResilienceTest")

# Number of execution of one benchmark
# set(LBMRESILIENCETEST_BATCH_NUM 5)

# LBM Build Compilation Options

set(LBM_RESILIENCE_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(LBM_RESILIENCE_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  LBM_RESILIENCE
  GIT_REPOSITORY https://github.com/Syllo/lbm.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/LBMResilienceTest"
  )

set(LBM_RESILIENCE_common_arguments
  -q
  )

# Variable benchmark-name benchmark-options
set(karman_vortex_small       karman-vortex-small       -t 1000 -x 511  -y 150 -r 0.2 -s 1. -o "${LBM_RESILIENCE_RESULTS_DIR}/karman-votex-small.dat")
set(karman_vortex_elongated   karman-vortex-elongated   -t 250  -x 1023 -y 150 -r 0.2 -s 1. -o "${LBM_RESILIENCE_RESULTS_DIR}/karman-votex-elongated.dat")
set(karmak_vortex_large_width karman-vortex-large-width -t 3700 -x 200  -y 175 -r 0.4 -s 1. -o "${LBM_RESILIENCE_RESULTS_DIR}/karman-votex-large-width.dat")

# Benchmarks to run for LBM

set(LBM_RESILIENCE_BENCHMARKS
  karman_vortex_small
  karman_vortex_elongated
  karmak_vortex_large_width
  )

# Register bench targets

set(LBM_RESILIENCE_BENCHMARKS_TARGET lbm_resilience-benchmark)

add_custom_target(${LBM_RESILIENCE_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS LBM_RESILIENCE_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND LBM_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${LBM_RESILIENCE_RESILIENCE_RESULTS_DIR}"
    COMMAND lbmResilienceTest ${bench_arguments} ${LBM_RESILIENCE_common_arguments} 1> "${LBM_RESILIENCE_RESILIENCE_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from LBM: ${bench_name}"
    VERBATIM)
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET} "${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
endforeach()

add_custom_command(OUTPUT "${LBM_RESILIENCE_RESILIENCE_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${LBM_RESILIENCE_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(lbm_Resilience)

# Benchmark results gathering

set(LBM_RESILIENCE_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/LBMGathered.dat")
set(LBM_RESILIENCE_DATA_COLUMN_NAME "Time")
set(LBM_RESILIENCE_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'")

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${LBM_RESILIENCE_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${LBM_RESILIENCE_BENCH_LINK_OPTION})

FetchContent_GetProperties(LBM_RESILIENCE)
if (NOT lbm_resilience_POPULATED)
  message(STATUS "Fetching LBMResilienceTest repository...")
  FetchContent_Populate(LBM_RESILIENCE)
  add_subdirectory(${lbm_resilience_SOURCE_DIR} ${lbm_resilience_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED LBMRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(LBMRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(LBMRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
