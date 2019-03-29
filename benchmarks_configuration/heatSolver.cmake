include(FetchContent)
include(CheckIPOSupported)

set(HEATSOLVER_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/heatSolver")

# Number of execution of one benchmark
#set(HEATSOLVER_BATCH_NUM 5)

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
  heatSolver
  GIT_REPOSITORY https://github.com/Syllo/HeatSolver.git
  GIT_TAG origin/master
  SOURCE_DIR "${BENCHMARKS_DIR}/heatSolver"
  )

set(heat_common_arguments
  -x 1000
  -y 1000)

# Variable benchmark-name benchmark-options
set(heat_jacobi jacobi -j -o "${HEATSOLVER_RESULTS_DIR}/jacobi-data.dat")
set(heat_jacobi_parallel jacobi-parallel -j -p)
set(heat_jacobi_vectorized jacobi-vectorized -j -v)
set(heat_jacobi_parallel_tiled jacobi-parallel-tiled -j -t)

set(heat_over_relaxation over-relaxation -r -o "${HEATSOLVER_RESULTS_DIR}/overRelaxation-data.dat")
set(heat_over_relaxation_parallel over-relaxation-parallel -r -p)
set(heat_over_relaxation_vectorized over-relaxation-vectorized -r -v)
set(heat_over_relaxation_parallel_tiled over-relaxation-parallel-tiled -r -t)

set(heat_gauss_seidel gauss-seidel -o "${HEATSOLVER_RESULTS_DIR}/gaussSeidel-data.dat")
set(heat_gauss_seidel_parallel gauss-seidel-parallel -g -p)
set(heat_gauss_seidel_parallel_tiled gauss-seidel-parallel-tiled -g -t)

# Benchmarks to run for heatSolver

set(HEATSOLVER_BENCHMARKS
  heat_jacobi
  heat_jacobi_vectorized
  heat_jacobi_parallel
  heat_jacobi_parallel_tiled
  heat_over_relaxation
  heat_over_relaxation_vectorized
  heat_over_relaxation_parallel
  heat_over_relaxation_parallel_tiled
  heat_gauss_seidel
  heat_gauss_seidel_parallel
  heat_gauss_seidel_parallel_tiled
  )

# Benchmark results gathering

set(HEATSOLVER_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/heatSolverGathered.dat")
set(HEATSOLVER_DATA_COLUMN_NAME "Time")
set(HEATSOLVER_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'")

# Register bench targets

set(HEATSOLVER_BENCH_TARGET_PREFIX "heatsolver-bench")

add_custom_target(${HEATSOLVER_BENCH_TARGET_PREFIX}-move
  COMMAND "${PROJECT_SOURCE_DIR}/helper_scripts/$<PLATFORM_ID>/move_benchmark_results.sh" ${HEATSOLVER_RESULTS_DIR})
add_custom_target(${HEATSOLVER_BENCH_TARGET_PREFIX}
  COMMAND "${PROJECT_SOURCE_DIR}/helper_scripts/$<PLATFORM_ID>/move_benchmark_results.sh" ${HEATSOLVER_RESULTS_DIR})
foreach(BENCHMARK IN LISTS HEATSOLVER_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND HEATSOLVER_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${HEATSOLVER_BENCH_TARGET_PREFIX}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory ${HEATSOLVER_RESULTS_DIR}
    COMMAND heatsolver ${bench_arguments} ${heat_common_arguments} 1> "${HEATSOLVER_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from heatSolver: ${bench_name}"
    VERBATIM)
  add_dependencies(${HEATSOLVER_BENCH_TARGET_PREFIX} "${HEATSOLVER_BENCH_TARGET_PREFIX}-${bench_name}")
endforeach()

add_dependencies(bench heatsolver-bench)

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${HEAT_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${HEAT_BENCH_LINK_OPTION})

FetchContent_GetProperties(heatSolver)
if (NOT heatsolver_POPULATED)
  message(STATUS "Fetching HeatSolver repository...")
  FetchContent_Populate(heatSolver)
  add_subdirectory(${heatsolver_SOURCE_DIR} ${heatsolver_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED HEATSOLVER_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(HEATSOLVER_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(HEATSOLVER_BATCH_NUM 1)
  endif()
endif()
