include(FetchContent)
include(CheckIPOSupported)

set(LBMRESILIENCETEST_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/lbmResilienceTest")

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
foreach(bench_rand IN ITEMS "01" "02" "03" "04" "05" "06" "07" "08" "09")
  set(karman_vortex_small_rand${bench_rand}       karman-vortex-small-rand${bench_rand}       -t 1000 -x 511  -y 150 -r 0.2 -s 1. -R ${bench_rand} -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-small-rand${bench_rand}.dat")
  set(karman_vortex_small_rand${bench_rand}_interpol       karman-vortex-small-rand${bench_rand}-interpol       -t 1000 -x 511  -y 150 -r 0.2 -s 1. -R ${bench_rand} -I -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-small-rand${bench_rand}-interpol.dat")
  set(karman_vortex_small_sort${bench_rand}       karman-vortex-small-sort${bench_rand}       -t 1000 -x 511  -y 150 -r 0.2 -s 1. -R ${bench_rand} -S -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-small-sort${bench_rand}.dat")
  list(APPEND LBM_RESILIENCE_TEST_SMALL_BENCHMARKS karman_vortex_small_rand${bench_rand} karman_vortex_small_rand${bench_rand}_interpol karman_vortex_small_sort${bench_rand})
  set(karman_vortex_elongated_rand${bench_rand}   karman-vortex-elongated-rand${bench_rand}   -t 250  -x 1023 -y 150 -r 0.2 -s 1. -R ${bench_rand} -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-elongated-rand${bench_rand}.dat")
  set(karman_vortex_elongated_rand${bench_rand}_interpol   karman-vortex-elongated-rand${bench_rand}-interpol   -t 250  -x 1023 -y 150 -r 0.2 -s 1. -R ${bench_rand} -I -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-elongated-rand${bench_rand}-interpol.dat")
  set(karman_vortex_elongated_sort${bench_rand}   karman-vortex-elongated-sort${bench_rand}   -t 250  -x 1023 -y 150 -r 0.2 -s 1. -R ${bench_rand} -S -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-elongated-sort${bench_rand}.dat")
  list(APPEND LBM_RESILIENCE_TEST_ELONGATED_BENCHMARKS karman_vortex_elongated_rand${bench_rand} karman_vortex_elongated_rand${bench_rand}_interpol karman_vortex_elongated_sort${bench_rand})
  set(karmak_vortex_large_width_rand${bench_rand} karman-vortex-large-width-rand${bench_rand} -t 3700 -x 200  -y 175 -r 0.4 -s 1. -R ${bench_rand} -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-large-width-rand${bench_rand}.dat")
  set(karmak_vortex_large_width_rand${bench_rand}_interpol karman-vortex-large-width-rand${bench_rand}-interpol -t 3700 -x 200  -y 175 -r 0.4 -s 1. -R ${bench_rand} -I -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-large-width-rand${bench_rand}-interpol.dat")
  set(karmak_vortex_large_width_sort${bench_rand} karman-vortex-large-width-sort${bench_rand} -t 3700 -x 200  -y 175 -r 0.4 -s 1. -R ${bench_rand} -S -o "${LBMRESILIENCETEST_RESULTS_DIR}/karman-votex-large-width-sort${bench_rand}.dat")
  list(APPEND LBM_RESILIENCE_TEST_LARGE_BENCHMARKS karmak_vortex_large_width_rand${bench_rand} karmak_vortex_large_width_rand${bench_rand}_interpol karmak_vortex_large_width_sort${bench_rand})
endforeach()

# Register bench targets

set(LBM_RESILIENCE_BENCHMARKS_TARGET lbm-resilience-benchmark)

add_custom_target(${LBM_RESILIENCE_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS LBM_RESILIENCE_TEST_SMALL_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND LBM_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${LBMRESILIENCETEST_RESULTS_DIR}"
    COMMAND lbmResilienceTest ${bench_arguments} ${LBM_RESILIENCE_common_arguments} 1> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/LBMResilienceTest/script/error.R "${LBM_RESULTS_DIR}/karman-votex-small.dat" "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from LBM Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET} "${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} lbm-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS LBM_RESILIENCE_TEST_ELONGATED_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND LBM_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${LBMRESILIENCETEST_RESULTS_DIR}"
    COMMAND lbmResilienceTest ${bench_arguments} ${LBM_RESILIENCE_common_arguments} 1> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/LBMResilienceTest/script/error.R "${LBM_RESULTS_DIR}/karman-vortex-elongated.dat" "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from LBM Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET} "${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} lbm-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS LBM_RESILIENCE_TEST_LARGE_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND LBM_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${LBMRESILIENCETEST_RESULTS_DIR}"
    COMMAND lbmResilienceTest ${bench_arguments} ${LBM_RESILIENCE_common_arguments} 1> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/LBMResilienceTest/script/error.R "${LBM_RESULTS_DIR}/karman-vortex-large-width.dat" "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${LBMRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from LBM Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET} "${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${LBM_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} lbm-run-benchmarks)
endforeach()

add_custom_command(OUTPUT "${LBMRESILIENCETEST_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${LBM_RESILIENCE_BENCHMARKS_TARGET} -j 8
  VERBATIM)

generate_benchmark_targets_for(lbmResilienceTest)

# Benchmark results gathering

set(LBMRESILIENCETEST_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/lbmResilienceTestGathered.dat")
set(LBMRESILIENCETEST_DATA_COLUMN_NAME "Time" "Mean_Error" "Max_Error" "Quartile_1" "Median" "Quartile_3")
set(LBMRESILIENCETEST_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Mean ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep 'Max. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '1st Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  "grep 'Median ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '3rd Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  )

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
