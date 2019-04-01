include(FetchContent)
include(CheckIPOSupported)

set(FLUIDSOLVER_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/fluidSolver")

# Number of execution of one benchmark
#set(FLUIDSOLVER_BATCH_NUM 5)

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
  fluidSolver
  GIT_REPOSITORY https://github.com/Syllo/FluidSolver.git
  GIT_TAG origin/master
  SOURCE_DIR "${BENCHMARKS_DIR}/fluidSolver"
  )

set(fluid_common_arguments "")

# Variable benchmark-name benchmark-options
set(base_2d  base-2d  -s "${BENCHMARKS_DIR}/fluidSolver/simulation_setup/2d/base" -o "${FLUIDSOLVER_RESULTS_DIR}/base2d-data.dat")
set(flame_2d flame-2d -s "${BENCHMARKS_DIR}/fluidSolver/simulation_setup/2d/flame" -o "${FLUIDSOLVER_RESULTS_DIR}/flame2d-data.dat")
set(huge_2d  huge-2d  -s "${BENCHMARKS_DIR}/fluidSolver/simulation_setup/2d/huge" -o "${FLUIDSOLVER_RESULTS_DIR}/huge2d-data.dat")
set(base_3d  base-3d  --3d -s "${BENCHMARKS_DIR}/fluidSolver/simulation_setup/3d/base" -o "${FLUIDSOLVER_RESULTS_DIR}/base3d-data.dat")
set(huge_3d  huge-3d  --3d -s "${BENCHMARKS_DIR}/fluidSolver/simulation_setup/3d/huge") # -o "${FLUIDSOLVER_RESULTS_DIR}/huge3d-data.dat") # ~240Mo

# Benchmarks to run for fluidSolver

set(FLUIDSOLVER_BENCHMARKS
  base_2d
  flame_2d
  huge_2d
  base_3d
  huge_3d
  )

# Benchmark results gathering

set(FLUIDSOLVER_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/fluidSolverGathered.dat")
set(FLUIDSOLVER_DATA_COLUMN_NAME "Time")
set(FLUIDSOLVER_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'")

# Register bench targets

set(FLUIDSOLVER_BENCHMARKS_TARGET fluidsolver-benchmark)

add_custom_target(${FLUIDSOLVER_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS FLUIDSOLVER_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND FLUIDSOLVER_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${FLUIDSOLVER_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory ${FLUIDSOLVER_RESULTS_DIR}
    COMMAND fluidsolver ${bench_arguments} ${fluid_common_arguments} 1> "${FLUIDSOLVER_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from fluidSolver: ${bench_name}"
    VERBATIM)
  add_dependencies(${FLUIDSOLVER_BENCHMARKS_TARGET} "${FLUIDSOLVER_BENCHMARKS_TARGET}-${bench_name}")
endforeach()

add_custom_command(OUTPUT "${FLUIDSOLVER_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${FLUIDSOLVER_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(fluidsolver)

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${FLUID_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${FLUID_BENCH_LINK_OPTION})

FetchContent_GetProperties(fluidSolver)
if (NOT fluidsolver_POPULATED)
  message(STATUS "Fetching FluidSolver repository...")
  FetchContent_Populate(fluidSolver)
  add_subdirectory(${fluidsolver_SOURCE_DIR} ${fluidsolver_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED FLUIDSOLVER_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(FLUIDSOLVER_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(FLUIDSOLVER_BATCH_NUM 1)
  endif()
endif()
