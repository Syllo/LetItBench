include(FetchContent)
include(CheckIPOSupported)

set(KMEANSRESILIENCETEST_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/KMeansResilienceTest")

# Number of execution of one benchmark
#set(KMEANSRESILIENCETEST_BATCH_NUM 5)

# K-Meanns Build Compilation Options

set(KMEANS_RESILIENCE_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(KMEANS_RESILIENCE_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  KMeans_Resilience
  GIT_REPOSITORY https://github.com/Syllo/K-Means.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/KMeansResilienceTest"
  )

set(KMeans_Resilience_common_arguments
  -c 6
  )

# Variable benchmark-name benchmark-options

foreach(settle_at IN ITEMS "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15")
  foreach(invalidate_num IN ITEMS "0" "5" "10" "15" "20" "25" "30" "40" "50")
    set(vegetables_large_settle${settle_at}_invalidate${invalidate_num}  vegetables-large-settle${settle_at}-invalidate${invalidate_num} -S ${settle_at} -I ${invalidate_num} -i "${BENCHMARKS_DIR}/KMeans/images/vegetables_4168x3072.png" -o "${KMEANSRESILIENCETEST_RESULTS_DIR}/vegetables-large-settle${settle_at}-invalidate${invalidate_num}.png")
    list(APPEND KMEAN_RESILIENCE_TEST_VEGETABLE_BENCHMARKS vegetables_large_settle${settle_at}_invalidate${invalidate_num})
    set(wolf_large_settle${settle_at}_invalidate${invalidate_num}        wolf-large-settle${settle_at}-invalidate${invalidate_num}       -S ${settle_at} -I ${invalidate_num} -i "${BENCHMARKS_DIR}/KMeans/images/wolf_4288x2848.png"       -o "${KMEANSRESILIENCETEST_RESULTS_DIR}/wolf-large-settle${settle_at}-invalidate${invalidate_num}.png")
    list(APPEND KMEAN_RESILIENCE_TEST_WOLF_BENCHMARKS wolf_large_settle${settle_at}_invalidate${invalidate_num})
    set(nebula_large_settle${settle_at}_invalidate${invalidate_num}      nebula-large-settle${settle_at}-invalidate${invalidate_num}     -S ${settle_at} -I ${invalidate_num} -i "${BENCHMARKS_DIR}/KMeans/images/nebula_3000x2785.png"     -o "${KMEANSRESILIENCETEST_RESULTS_DIR}/nebula-large-settle${settle_at}-invalidate${invalidate_num}.png")
    list(APPEND KMEAN_RESILIENCE_TEST_NEBULA_BENCHMARKS nebula_large_settle${settle_at}_invalidate${invalidate_num})
    set(bird_large_settle${settle_at}_invalidate${invalidate_num}        bird-large-settle${settle_at}-invalidate${invalidate_num}       -S ${settle_at} -I ${invalidate_num} -i "${BENCHMARKS_DIR}/KMeans/images/bird_2560x1600.png"       -o "${KMEANSRESILIENCETEST_RESULTS_DIR}/bird-large-settle${settle_at}-invalidate${invalidate_num}.png")
    list(APPEND KMEAN_RESILIENCE_TEST_BIRD_BENCHMARKS bird_large_settle${settle_at}_invalidate${invalidate_num})
  endforeach()
endforeach()

# Register bench targets

set(KMEANS_RESILIENCE_BENCHMARKS_TARGET kmeans-resilience-benchmark)

add_custom_target(${KMEANS_RESILIENCE_BENCHMARKS_TARGET})

foreach(BENCHMARK IN LISTS KMEAN_RESILIENCE_TEST_VEGETABLE_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND KMEANS_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${KMEANSRESILIENCETEST_RESULTS_DIR}"
    COMMAND kmeansResilienceTest ${bench_arguments} ${KMeans_Resilience_common_arguments} 1> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND kmeansResilienceTest -i "${KMEANS_RESULTS_DIR}/vegetables_large.png" -C "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}.png" >> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from KMeans Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${KMEANS_RESILIENCE_BENCHMARKS_TARGET} "${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}" kmeans-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS KMEAN_RESILIENCE_TEST_WOLF_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND KMEANS_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${KMEANSRESILIENCETEST_RESULTS_DIR}"
    COMMAND kmeansResilienceTest ${bench_arguments} ${KMeans_Resilience_common_arguments} 1> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND kmeansResilienceTest -i "${KMEANS_RESULTS_DIR}/wolf_large.png" -C "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}.png" >> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from KMeans Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${KMEANS_RESILIENCE_BENCHMARKS_TARGET} "${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}" kmeans-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS KMEAN_RESILIENCE_TEST_NEBULA_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND KMEANS_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${KMEANSRESILIENCETEST_RESULTS_DIR}"
    COMMAND kmeansResilienceTest ${bench_arguments} ${KMeans_Resilience_common_arguments} 1> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND kmeansResilienceTest -i "${KMEANS_RESULTS_DIR}/nebula_large.png" -C "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}.png" >> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from KMeans Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${KMEANS_RESILIENCE_BENCHMARKS_TARGET} "${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}" kmeans-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS KMEAN_RESILIENCE_TEST_BIRD_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND KMEANS_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${KMEANSRESILIENCETEST_RESULTS_DIR}"
    COMMAND kmeansResilienceTest ${bench_arguments} ${KMeans_Resilience_common_arguments} 1> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND kmeansResilienceTest -i "${KMEANS_RESULTS_DIR}/bird_large.png" -C "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}.png" >> "${KMEANSRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from KMeans Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${KMEANS_RESILIENCE_BENCHMARKS_TARGET} "${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies("${KMEANS_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}" kmeans-run-benchmarks)
endforeach()

add_custom_command(OUTPUT "${KMEANSRESILIENCETEST_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${KMEANS_RESILIENCE_BENCHMARKS_TARGET} -j 8
  VERBATIM)

generate_benchmark_targets_for(kmeansResilienceTest)

# Benchmark results gathering

set(KMEANSRESILIENCETEST_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/KMeansResilienceTestGathered.dat")
set(KMEANSRESILIENCETEST_DATA_COLUMN_NAME "Time" "Kernel_Iterations" "Error")
set(KMEANSRESILIENCETEST_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Converged ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  "grep 'Error ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2 | tr -d \"%\""
  )

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${KMEANS_RESILIENCE_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${KMEANS_RESILIENCE_BENCH_LINK_OPTION})

FetchContent_GetProperties(KMeans_Resilience)
if (NOT kmeans_resilience_POPULATED)
  message(STATUS "Fetching K-MeansResilienceTest repository...")
  FetchContent_Populate(KMeans_Resilience)
  add_subdirectory(${kmeans_resilience_SOURCE_DIR} ${kmeans_resilience_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED KMEANSRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(KMEANSRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(KMEANSRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
