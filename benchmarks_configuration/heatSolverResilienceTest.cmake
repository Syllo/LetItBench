include(FetchContent)
include(CheckIPOSupported)

set(HEATSOLVERRESILIENCETEST_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/heatSolverResilienceTest")

# Number of execution of one benchmark
#set(HEATSOLVERRESILIENCETEST_BATCH_NUM 5)

# HeatSolver Build Compilation Options

set(HEAT_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(HEAT_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  heatSolverResilienceTest
  GIT_REPOSITORY https://github.com/Syllo/HeatSolver.git
  GIT_TAG origin/resilience_tests
  SOURCE_DIR "${BENCHMARKS_DIR}/heatSolverResilienceTest"
  )

set(heat_common_arguments
  -x 1000
  -y 1000
  -i 30605)

# Variable benchmark-name benchmark-options
set(heat_jacobi_rand_002 rand-002 -j -R 0.02 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-002.dat")
set(heat_jacobi_rand_004 rand-004 -j -R 0.04 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-004.dat")
set(heat_jacobi_rand_006 rand-006 -j -R 0.06 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-006.dat")
set(heat_jacobi_rand_008 rand-008 -j -R 0.08 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-008.dat")
set(heat_jacobi_rand_010 rand-010 -j -R 0.10 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-010.dat")
set(heat_jacobi_rand_012 rand-012 -j -R 0.12 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-012.dat")
set(heat_jacobi_rand_014 rand-014 -j -R 0.14 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-014.dat")
set(heat_jacobi_rand_016 rand-016 -j -R 0.16 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-016.dat")
set(heat_jacobi_rand_018 rand-018 -j -R 0.18 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-018.dat")
set(heat_jacobi_rand_020 rand-020 -j -R 0.20 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/rand-020.dat")
set(heat_jacobi_perforation_2 perforation-2 -j -X 2 -Y 2 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/perforation-2.dat")
set(heat_jacobi_perforation_3 perforation-3 -j -X 3 -Y 3 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/perforation-3.dat")
set(heat_jacobi_perforation_4 perforation-4 -j -X 4 -Y 4 -o "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/perforation-4.dat")

# Benchmarks to run for heatSolver

set(HEATSOLVERRESILIENCETEST_BENCHMARKS
  heat_jacobi_rand_002
  heat_jacobi_rand_004
  heat_jacobi_rand_006
  heat_jacobi_rand_008
  heat_jacobi_rand_010
  heat_jacobi_rand_012
  heat_jacobi_rand_014
  heat_jacobi_rand_016
  heat_jacobi_rand_018
  heat_jacobi_rand_020
  heat_jacobi_perforation_2
  heat_jacobi_perforation_3
  heat_jacobi_perforation_4
  )

# Benchmark results gathering

set(HEATSOLVERRESILIENCETEST_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/heatSolverResilienceTestGathered.dat")
set(HEATSOLVERRESILIENCETEST_DATA_COLUMN_NAME "Time" "Mean_Error" "Max_Error" "Quartile_1" "Median" "Quartile_3")
set(HEATSOLVERRESILIENCETEST_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Mean ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep 'Max. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '1st Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  "grep 'Median ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '3rd Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  )

# Register bench targets

set(HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET heatsolverresiliencetest-benchmark)

add_custom_target(${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS HEATSOLVERRESILIENCETEST_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND HEATSOLVERRESILIENCETEST_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory ${HEATSOLVERRESILIENCETEST_RESULTS_DIR}
    COMMAND heatSolverResilienceTest ${bench_arguments} ${heat_common_arguments} 1> "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/heatSolverResilienceTest/script/error.R "${HEATSOLVER_RESULTS_DIR}/jacobi.dat" "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from heatSolverResilienceTest: ${bench_name}"
    VERBATIM)
  add_dependencies(${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET} "${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies("${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}" heatsolver-run-benchmarks)
endforeach()


add_custom_command(OUTPUT "${HEATSOLVERRESILIENCETEST_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${HEATSOLVERRESILIENCETEST_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(heatSolverResilienceTest)

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${HEAT_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${HEAT_BENCH_LINK_OPTION})

FetchContent_GetProperties(heatSolverResilienceTest)
if (NOT heatsolverresiliencetest_POPULATED)
  message(STATUS "Fetching HeatSolverResilienceTest repository...")
  FetchContent_Populate(heatSolverResilienceTest)
  add_subdirectory(${heatsolverresiliencetest_SOURCE_DIR} ${heatsolverresiliencetest_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED HEATSOLVERRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(HEATSOLVERRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(HEATSOLVERRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
