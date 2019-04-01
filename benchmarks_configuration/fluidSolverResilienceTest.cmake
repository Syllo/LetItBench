include(FetchContent)
include(CheckIPOSupported)

set(FLUIDSOLVERRESILIENCETEST_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/fluidSolverResilienceTest")

# Number of execution of one benchmark
#set(FLUIDSOLVERRESILIENCETEST_BATCH_NUM 5)

# FluidSolver Build Compilation Options

set(FLUID_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(FLUID_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  fluidSolverResilienceTest
  GIT_REPOSITORY https://github.com/Syllo/FluidSolver.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/fluidSolverResilienceTest"
  )

set(fluid_common_arguments "")

# Variable benchmark-name benchmark-options
foreach(bench_id IN ITEMS base flame huge)
  foreach(bench_rand IN ITEMS "02" "04" "06" "08" "10" "12" "14" "16" "18" "20")
    set(${bench_id}_rand_${bench_rand}  fluid-${bench_id}-rand-${bench_rand} -R  0.${bench_rand} -s
      "${BENCHMARKS_DIR}/fluidSolverResilienceTest/simulation_setup/2d/${bench_id}" -o "${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}/fluid-${bench_id}-rand-${bench_rand}-data.dat")
    list(APPEND FLUIDSOLVERRESILIENCETEST_${bench_id}_BENCHMARKS ${bench_id}_rand_${bench_rand})
  endforeach()
endforeach()

set(FLUIDSOLVERRESILIENCETEST_BENCHMARKS
  ${FLUIDSOLVERRESILIENCETEST_base_BENCHMARKS}
  ${FLUIDSOLVERRESILIENCETEST_flame_BENCHMARKS}
  ${FLUIDSOLVERRESILIENCETEST_huge_BENCHMARKS})

# Benchmark results gathering

set(FLUIDSOLVERRESILIENCETEST_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/fluidSolverResilienceTestGathered.dat")
set(FLUIDSOLVERRESILIENCETEST_DATA_COLUMN_NAME "Time" "Mean_Error" "Max_Error" "Quartile_1" "Median" "Quartile_3")
set(FLUIDSOLVERRESILIENCETEST_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Mean ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep 'Max. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '1st Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  "grep 'Median ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '3rd Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  )

# Register bench targets

set(FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET fluidsolverresiliencetest-benchmark)

add_custom_target(${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET})
foreach(bench_id IN ITEMS base flame huge)
  foreach(BENCHMARK IN LISTS FLUIDSOLVERRESILIENCETEST_${bench_id}_BENCHMARKS)
    list(GET ${BENCHMARK} 0 bench_name)
    list(APPEND FLUIDSOLVERRESILIENCETEST_BENCH_TARGET_LIST ${bench_name})
    list(LENGTH ${BENCHMARK} bench_num_args)
    if(${bench_num_args} GREATER 1)
      list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
    else()
      unset(bench_arguments)
    endif()
    add_custom_target("${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}"
      ${CMAKE_COMMAND} -E make_directory ${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}
      COMMAND fluidSolverResilienceTest ${bench_arguments} ${fluid_common_arguments} 1> "${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
      COMMAND Rscript ${BENCHMARKS_DIR}/fluidSolverResilienceTest/script/error2d.R "${FLUIDSOLVER_RESULTS_DIR}/${bench_id}2d-data.dat"
      "${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}-data.dat" >> "${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
      COMMAND_EXPAND_LISTS
      COMMENT "Running benchmark from fluidSolverResilienceTest: ${bench_name}"
      VERBATIM)
    add_dependencies(${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET} "${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}")
    add_dependencies("${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET}-${bench_name}" fluidsolver-run-benchmarks)
  endforeach()
endforeach()

add_custom_command(OUTPUT "${FLUIDSOLVERRESILIENCETEST_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${FLUIDSOLVERRESILIENCETEST_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(fluidsolverresiliencetest)

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${FLUID_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${FLUID_BENCH_LINK_OPTION})

FetchContent_GetProperties(fluidSolverResilienceTest)
if (NOT fluidsolverresiliencetest_POPULATED)
  message(STATUS "Fetching FluidSolverResilienceTest repository...")
  FetchContent_Populate(fluidSolverResilienceTest)
  add_subdirectory(${fluidsolverresiliencetest_SOURCE_DIR} ${fluidsolverresiliencetest_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED FLUIDSOLVERRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(FLUIDSOLVERRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(FLUIDSOLVERRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
