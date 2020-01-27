include(FetchContent)
include(CheckIPOSupported)

set(FDTDRESILIENCETEST_RESULTS_DIR "${BENCHMARKS_RESULTS_DIR}/FDTDResilienceTest")

# Number of execution of one benchmark
# set(FDTDRESILIENCETEST_BATCH_NUM 5)

# FDTD Build Compilation Options

set(FDTD_RESILIENCE_BENCH_COMPILE_OPTION
  #"-Os"
  #"-march=skylake"
  )

set(FDTD_RESILIENCE_BENCH_LINK_OPTION
  #"-Wl,-z,now"
  )

if (NOT DEFINED USE_IPO)
  set(USE_IPO TRUE) # Inter Procedural Optimization (lto) ON by default if available
else()
  set(WAS_DEFINED_IPO TRUE)
endif()

# Benchmark Source Location

FetchContent_Declare(
  FDTD_RESILIENCE
  GIT_REPOSITORY https://github.com/Syllo/fdtd.git
  GIT_TAG origin/resilience_test
  SOURCE_DIR "${BENCHMARKS_DIR}/FDTDResilienceTest"
  )

set(FDTD_RESILIENCE_common_arguments
  -q
  )

# Variable benchmark-name benchmark-options
foreach(bench_rand IN ITEMS "01" "02" "03" "04" "05" "06" "07" "08" "09")
  set(2D_s0_rand${bench_rand}  2D-s0-rand${bench_rand} -2 -s 0 -i 2200   -x 0.00002  -y 0.00005 -R 0.${bench_rand} -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s0-rand${bench_rand}.dat")
  set(2D_s0_rand${bench_rand}_interpol  2D-s0-rand${bench_rand}-interpol -2 -s 0 -i 2200   -x 0.00002  -y 0.00005 -R 0.${bench_rand} -I -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s0-rand${bench_rand}-interpol.dat")
  list(APPEND FDTD_RESILIENCE_S0_BENCHMARKS 2D_s0_rand${bench_rand} 2D_s0_rand${bench_rand}_interpol)
  set(2D_s1_rand${bench_rand}  2D-s1-rand${bench_rand} -2 -s 1 -i 1500   -x 0.00003  -y 0.00003 -R 0.${bench_rand} -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s1-rand${bench_rand}.dat")
  set(2D_s1_rand${bench_rand}_interpol  2D-s1-rand${bench_rand}-interpol -2 -s 1 -i 1500   -x 0.00003  -y 0.00003 -R 0.${bench_rand} -I -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s1-rand${bench_rand}-interpol.dat")
  list(APPEND FDTD_RESILIENCE_S1_BENCHMARKS 2D_s1_rand${bench_rand} 2D_s1_rand${bench_rand}_interpol)
  set(2D_s2_rand${bench_rand}  2D-s2-rand${bench_rand} -2 -s 2 -i 2000   -x 0.00004  -y 0.00004 -R 0.${bench_rand} -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s2-rand${bench_rand}.dat")
  set(2D_s2_rand${bench_rand}_interpol  2D-s2-rand${bench_rand}-interpol -2 -s 2 -i 2000   -x 0.00004  -y 0.00004 -R 0.${bench_rand} -I -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s2-rand${bench_rand}-interpol.dat")
  list(APPEND FDTD_RESILIENCE_S2_BENCHMARKS 2D_s2_rand${bench_rand} 2D_s2_rand${bench_rand}_interpol)
endforeach()
foreach(bench_rand IN ITEMS "10" "20" "30" "40" "50" "60" "70" "80" "90")
  set(2D_s0_sort${bench_rand}  2D-s0-sort${bench_rand} -2 -s 0 -i 2200   -x 0.00002  -y 0.00005 -R 0.${bench_rand} -S -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s0-sort${bench_rand}.dat")
  list(APPEND FDTD_RESILIENCE_S0_BENCHMARKS 2D_s0_sort${bench_rand})
  set(2D_s1_sort${bench_rand}  2D-s1-sort${bench_rand} -2 -s 1 -i 1500   -x 0.00003  -y 0.00003 -R 0.${bench_rand} -S -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s1-sort${bench_rand}.dat")
  list(APPEND FDTD_RESILIENCE_S1_BENCHMARKS 2D_s1_sort${bench_rand})
  set(2D_s2_sort${bench_rand}  2D-s2-sort${bench_rand} -2 -s 2 -i 2000   -x 0.00004  -y 0.00004 -R 0.${bench_rand} -S -o "${FDTDRESILIENCETEST_RESULTS_DIR}/2D-s2-sort${bench_rand}.dat")
  list(APPEND FDTD_RESILIENCE_S2_BENCHMARKS 2D_s2_sort${bench_rand})
endforeach()

# Register bench targets

set(FDTD_RESILIENCE_BENCHMARKS_TARGET fdtd-resilience-benchmark)

add_custom_target(${FDTD_RESILIENCE_BENCHMARKS_TARGET})
foreach(BENCHMARK IN LISTS FDTD_RESILIENCE_S0_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND FDTD_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${FDTDRESILIENCETEST_RESULTS_DIR}"
    COMMAND fdtdResilienceTest ${bench_arguments} ${FDTD_RESILIENCE_common_arguments} 1> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/FDTDResilienceTest/script/error.R "${FDTD_RESULTS_DIR}/2D-s0.dat" "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from FDTD Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET} "${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} fdtd-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS FDTD_RESILIENCE_S1_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND FDTD_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${FDTDRESILIENCETEST_RESULTS_DIR}"
    COMMAND fdtdResilienceTest ${bench_arguments} ${FDTD_RESILIENCE_common_arguments} 1> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/FDTDResilienceTest/script/error.R "${FDTD_RESULTS_DIR}/2D-s1.dat" "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from FDTD Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET} "${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} fdtd-run-benchmarks)
endforeach()

foreach(BENCHMARK IN LISTS FDTD_RESILIENCE_S2_BENCHMARKS)
  list(GET ${BENCHMARK} 0 bench_name)
  list(APPEND FDTD_RESILIENCE_BENCH_TARGET_LIST ${bench_name})
  list(LENGTH ${BENCHMARK} bench_num_args)
  if(${bench_num_args} GREATER 1)
    list(SUBLIST ${BENCHMARK} 1 -1 bench_arguments)
  else()
    unset(bench_arguments)
  endif()
  add_custom_target("${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}"
    ${CMAKE_COMMAND} -E make_directory "${FDTDRESILIENCETEST_RESULTS_DIR}"
    COMMAND fdtdResilienceTest ${bench_arguments} ${FDTD_RESILIENCE_common_arguments} 1> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND Rscript ${BENCHMARKS_DIR}/FDTDResilienceTest/script/error.R "${FDTD_RESULTS_DIR}/2D-s2.dat" "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}.dat" >> "${FDTDRESILIENCETEST_RESULTS_DIR}/${bench_name}" 2>&1
    COMMAND_EXPAND_LISTS
    COMMENT "Running benchmark from FDTD Resilience Test: ${bench_name}"
    VERBATIM)
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET} "${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name}")
  add_dependencies(${FDTD_RESILIENCE_BENCHMARKS_TARGET}-${bench_name} fdtd-run-benchmarks)
endforeach()

add_custom_command(OUTPUT "${FDTDRESILIENCETEST_RESULTS_DIR}"
  COMMAND ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${FDTD_RESILIENCE_BENCHMARKS_TARGET} -j $(nproc)
  VERBATIM)

generate_benchmark_targets_for(fdtdResilienceTest)

# Benchmark results gathering

set(FDTDRESILIENCETEST_GATHER_LOCATION "${BENCHMARKS_RESULTS_DIR}/FDTDResilienceTestGathered.dat")
set(FDTDRESILIENCETEST_DATA_COLUMN_NAME "Time" "Mean_Error" "Max_Error" "Quartile_1" "Median" "Quartile_3")
set(FDTDRESILIENCETEST_DATA_EXTRACT_FN
  "grep 'Kernel time' \"$bench_result_location/$bench_name\" | cut -d ' ' -f 3 | tr -d 's'"
  "grep 'Mean ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep 'Max. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '1st Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  "grep 'Median ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 2"
  "grep '3rd Qu. ' \"$bench_result_location/$bench_name\" | tr -s ' ' | cut -d ' ' -f 3"
  )

# Fetching project

set(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS ${COMMON_BENCH_COMPILE_OPTION} ${FDTD_RESILIENCE_BENCH_COMPILE_OPTION})
set(ADDITIONAL_BENCHMARK_LINK_OPTIONS ${COMMON_BENCH_LINK_OPTION} ${FDTD_RESILIENCE_BENCH_LINK_OPTION})

FetchContent_GetProperties(FDTD_RESILIENCE)
if (NOT fdtd_resilience_POPULATED)
  message(STATUS "Fetching FDTDREsilienceTest repository...")
  FetchContent_Populate(FDTD_RESILIENCE)
  add_subdirectory(${fdtd_resilience_SOURCE_DIR} ${fdtd_resilience_BINARY_DIR})
endif()

unset(ADDITIONAL_BENCHMARK_COMPILE_OPTIONS)
unset(ADDITIONAL_BENCHMARK_LINK_OPTIONS)

if (DEFINED WAS_DEFINED_IPO)
  unset(WAS_DEFINED_IPO)
else()
  unset(USE_IPO)
endif()

if (NOT DEFINED FDTDRESILIENCETEST_BATCH_NUM)
  if (DEFINED COMMON_BATCH_NUM)
    set(FDTDRESILIENCETEST_BATCH_NUM ${COMMON_BATCH_NUM})
  else()
    set(FDTDRESILIENCETEST_BATCH_NUM 1)
  endif()
endif()
