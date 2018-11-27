set(BENCHMARKS_DIR "${PROJECT_SOURCE_DIR}/benchmarks_directory" CACHE PATH "Directory of benchmarks source code")
set(BENCHMARKS_RESULTS_DIR "${PROJECT_SOURCE_DIR}/benchmarks_result_directory" CACHE PATH "Directory where benchmark execution results are stored")

# Global number of benchmark runs for batch mode
# This setting can be overridden for by each benchmark application using the option in their configuration file

set(COMMON_BATCH_NUM 2)

# Benchmark Common Compilation Options
# (Prepended on benchmark specific compilation options)

set(COMMON_BENCH_COMPILE_OPTION
  "-O3"
  "-march=native"
  )

set(COMMON_BENCH_LINK_OPTION
  "-Wl,-z,now"
  )

# Force ON/OFF Inter Procedural Optimization (lto) for all benchmarks
#set(USE_IPO TRUE) # Possible values are TRUE or FALSE

# Benchmark configuration file
add_custom_target(bench)

set(BENCHMARK_SET
  heatSolver
  fluidSolver
  gol
  k-means)

foreach(BENCHMARK IN LISTS BENCHMARK_SET)
  include("${PROJECT_SOURCE_DIR}/benchmarks_configuration/${BENCHMARK}.cmake")
endforeach()

configure_file(${PROJECT_SOURCE_DIR}/helper_scripts/Linux/run_batch_script.sh.in
  ${PROJECT_BINARY_DIR}/helper_scripts/Linux/run_batch_script.sh
  @ONLY)

configure_file(
  ${PROJECT_BINARY_DIR}/helper_scripts/Linux/run_batch_script.sh
  ${PROJECT_BINARY_DIR}/helper_scripts/Darwin/run_batch_script.sh
  COPYONLY)

add_custom_target(batch-bench
  /bin/sh "${PROJECT_BINARY_DIR}/helper_scripts/$<PLATFORM_ID>/run_batch_script.sh")
