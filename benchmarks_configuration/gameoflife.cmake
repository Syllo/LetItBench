include(FetchContent)
include(CheckIPOSupported)

set(GAMEOFLIFE_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/gameOfLife")

# Number of execution of one benchmark
# set(GAMEOFLIFE_BATCH_NUM 5)

# Game of Life Build Compilation Options

set(GAMEOFLIFE_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(GAMEOFLIFE_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  gameOfLife
  GIT_REPOSITORY https://github.com/Syllo/gol.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/gameOfLife"
  )

set(gameOfLife_common_arguments
  )

# Variable benchmark-name benchmark-options
set(pattern_101 pattern-101 --generation 150000 "${BENCHMARKS_DIR}/gameOfLife/patterns/101.rle" --compare-rle "${BENCHMARKS_DIR}/gameOfLife/patterns/101.rle")
set(pattern_bunnies pattern-bunny --generation 2500 "${BENCHMARKS_DIR}/gameOfLife/patterns/bunnies.rle" -o "${GAMEOFLIFE_RESULTS_DIR}/bunnies-gen2500.rle")
set(pattern_turing_machine pattern-turing-machine --generation 1000 "${BENCHMARKS_DIR}/gameOfLife/patterns/turingmachine.rle"
  -o "${GAMEOFLIFE_RESULTS_DIR}/turingmachine-gen1000.rle")
set(pattern_clock pattern-clock --generation 30 "${BENCHMARKS_DIR}/gameOfLife/patterns/clock.rle" -o "${GAMEOFLIFE_RESULTS_DIR}/clock-gen30.rle")

set(pattern_101_sparse pattern-101-sparse --generation 150000 "${BENCHMARKS_DIR}/gameOfLife/patterns/101.rle" --compare-rle "${BENCHMARKS_DIR}/gameOfLife/patterns/101.rle" -i)
set(pattern_bunnies_sparse pattern-bunny-sparse --generation 2500 "${BENCHMARKS_DIR}/gameOfLife/patterns/bunnies.rle" -o "${GAMEOFLIFE_RESULTS_DIR}/bunnies-gen2500.rle" -i)
set(pattern_turing_machine_sparse pattern-turing-machine-sparse --generation 1000 "${BENCHMARKS_DIR}/gameOfLife/patterns/turingmachine.rle"
  -o "${GAMEOFLIFE_RESULTS_DIR}/turingmachine-gen1000.rle" -i)
set(pattern_clock_sparse pattern-clock-sparse --generation 30 "${BENCHMARKS_DIR}/gameOfLife/patterns/clock.rle" -o "${GAMEOFLIFE_RESULTS_DIR}/clock-gen30.rle" -i)

# Benchmarks to run for gameOfLife

set(GAMEOFLIFE_BENCHMARKS
  pattern_101
  pattern_bunnies
  pattern_turing_machine
  pattern_clock
  pattern_101_sparse
  pattern_bunnies_sparse
  pattern_turing_machine_sparse
  pattern_clock_sparse
  )

# Benchmark results gathering

set(GAMEOFLIFE_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/gameOfLifeGathered.dat")
set(GAMEOFLIFE_DATA_COLUMN_NAME "Time" "Percent_Allocated")
set(GAMEOFLIFE_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Percent allocated' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d '%'")

# Register bench targets

set(GAMEOFLIFE_BENCHMARKS_TARGET gameoflife-benchmark)

add_custom_target(${GAMEOFLIFE_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS GAMEOFLIFE_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND GAMEOFLIFE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${GAMEOFLIFE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory ${GAMEOFLIFE_RESULTS_DIR}
    COMMAND gol ${bench_arguments} ${gameOfLife_common_arguments} 1> "${GAMEOFLIFE_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from gameOfLife: ${bench_name}"
    VERBATIM)
  add_dependencies(${GAMEOFLIFE_BENCHMARKS_TARGET} "${GAMEOFLIFE_BENCHMARKS_TARGET}-${bench_name}")
endforeach()

add_custom_command(OUTPUT "${GAMEOFLIFE_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${GAMEOFLIFE_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(gameoflife)

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${GAMEOFLIFE_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${GAMEOFLIFE_BENCH_LINK_OPTION})

FetchContent_GetProperties(gameOfLife)
if (NOT gameoflife_POPULATED)
  message(STATUS "Fetching GameOfLife repository...")
  FetchContent_Populate(gameOfLife)
  add_subdirectory(${gameoflife_SOURCE_DIR} ${gameoflife_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED GAMEOFLIFE_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(GAMEOFLIFE_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(GAMEOFLIFE_BATCH_NUM 1)
  endif()
endif()
