include(FetchContent)
include(CheckIPOSupported)

set(KMEANS_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/KMeans")

# Number of execution of one benchmark
#set(KMEANS_BATCH_NUM 5)

# K-Meanns Build Compilation Options

set(KMEANS_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(KMEANS_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  KMeans
  GIT_REPOSITORY https://github.com/Syllo/K-Means.git
  GIT_TAG origin/master
  SOURCE_DIR "${BENCHMARKS_DIR}/KMeans"
  )

set(KMeans_common_arguments
  -c 6
  )

# Variable benchmark-name benchmark-options
set(vegetables_small  vegetables-small  -i "${BENCHMARKS_DIR}/KMeans/images/vegetables_640x471.png"   -o "${KMEANS_RESULTS_DIR}/vegetables_small.png")
set(vegetables_medium vegetables-medium -i "${BENCHMARKS_DIR}/KMeans/images/vegetables_1280x943.png"  -o "${KMEANS_RESULTS_DIR}/vegetables_medium.png")
set(vegetables_large  vegetables-large  -i "${BENCHMARKS_DIR}/KMeans/images/vegetables_4168x3072.png" -o "${KMEANS_RESULTS_DIR}/vegetables_large.png")
set(wolf_small        wolf-small        -i "${BENCHMARKS_DIR}/KMeans/images/wolf_640x425.png"         -o "${KMEANS_RESULTS_DIR}/wolf_small.png")
set(wolf_medium       wolf-medium       -i "${BENCHMARKS_DIR}/KMeans/images/wolf_1280x850.png"        -o "${KMEANS_RESULTS_DIR}/wolf_medium.png")
set(wolf_large        wolf-large        -i "${BENCHMARKS_DIR}/KMeans/images/wolf_4288x2848.png"       -o "${KMEANS_RESULTS_DIR}/wolf_large.png")
set(nebula_small      nebula-small      -i "${BENCHMARKS_DIR}/KMeans/images/nebula_640x594.png"       -o "${KMEANS_RESULTS_DIR}/nebula_small.png")
set(nebula_medium     nebula-medium     -i "${BENCHMARKS_DIR}/KMeans/images/nebula_1280x1188.png"     -o "${KMEANS_RESULTS_DIR}/nebula_medium.png")
set(nebula_large      nebula-large      -i "${BENCHMARKS_DIR}/KMeans/images/nebula_3000x2785.png"     -o "${KMEANS_RESULTS_DIR}/nebula_large.png")
set(bird_small        bird-small        -i "${BENCHMARKS_DIR}/KMeans/images/bird_640x400.png"         -o "${KMEANS_RESULTS_DIR}/bird_small.png")
set(bird_medium       bird-medium       -i "${BENCHMARKS_DIR}/KMeans/images/bird_1280x800.png"        -o "${KMEANS_RESULTS_DIR}/bird_medium.png")
set(bird_large        bird-large        -i "${BENCHMARKS_DIR}/KMeans/images/bird_2560x1600.png"       -o "${KMEANS_RESULTS_DIR}/bird_large.png")
# Benchmarks to run for KMeans

set(KMEANS_BENCHMARKS
  vegetables_small
  wolf_small
  nebula_small
  bird_small
  vegetables_medium
  wolf_medium
  nebula_medium
  bird_medium
  vegetables_large
  wolf_large
  nebula_large
  bird_large
  )

# Register bench targets

set(KMEANS_BENCHMARKS_TARGET kmeans-benchmark)

add_custom_target(${KMEANS_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS KMEANS_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND KMEANS_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${KMEANS_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${KMEANS_RESULTS_DIR}"
    COMMAND kmeans ${bench_arguments} ${KMeans_common_arguments} 1> "${KMEANS_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from KMeans: ${bench_name}"
    VERBATIM)
  add_dependencies(${KMEANS_BENCHMARKS_TARGET} "${KMEANS_BENCHMARKS_TARGET}-${bench_name}")
endforeach()

add_custom_command(OUTPUT "${KMEANS_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${KMEANS_BENCHMARKS_TARGET} -j 1
  VERBATIM)

generate_benchmark_targets_for(kmeans)

# Benchmark results gathering

set(KMEANS_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/KMeansGathered.dat")
set(KMEANS_DATA_COLUMN_NAME "Time")
set(KMEANS_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'")

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${KMEANS_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${KMEANS_BENCH_LINK_OPTION})

FetchContent_GetProperties(KMeans)
if (NOT kmeans_POPULATED)
  message(STATUS "Fetching K-Means repository...")
  FetchContent_Populate(KMeans)
  add_subdirectory(${kmeans_SOURCE_DIR} ${kmeans_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED KMEANS_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(KMEANS_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(KMEANS_BATCH_NUM 1)
  endif()
endif()
