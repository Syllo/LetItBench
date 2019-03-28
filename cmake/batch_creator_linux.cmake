function(generate_batch_for_bench OUTPUT_STRING_VAR_NAME BENCH_NAME)
  string(TOLOWER ${BENCH_NAME} BENCH_LOWER_NAME)
  set(SCRIPT_LINES "if [ ${${BENCH_NAME}_BATCH_NUM} -gt 0 ]")
  list(APPEND SCRIPT_LINES 
    "then" 
    "  printf \"\\\\n  Benchmark ${BENCH_LOWER_NAME} (${${BENCH_NAME}_BATCH_NUM} runs):\\\\n\""
    "  for i in ${${BENCH_NAME}_BENCH_TARGET_SUFFIX}"
    "  do"
    "    echo \"    - $i\""
    "  done"
    "  do_bench=true"
    "  printf \"\\\\nDo you wish to continue? (Y/n) 5 seconds to respond...\""
    "  read_char value"
    "  echo \"\""
    "  if [ \"x$value\" != \"x\" ]"
    "  then"
    "    if [ \"$value\" = n ] || [ \"$value\" = N ]"
    "    then"
    "      do_bench=false"
    "    fi"
    "  fi"
    "  if [ $do_bench = \"true\" ]"
    "  then"
    "    n_batch=1"
    "    while [ $n_batch -le ${${BENCH_NAME}_BATCH_NUM} ]"
    "    do"
    "      printf \"\\\\n[$\{cian_color\}BENCH INFO$\{reset_color\}] Running batch $n_batch/${${BENCH_NAME}_BATCH_NUM} of HeatSolver\\\\n\\\\n\""
    "      ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${${BENCH_NAME}_BENCH_TARGET_PREFIX}"
    "      n_batch=$((n_batch+1))"
    "    done"
    "  fi"
    "fi"
    )
  list(JOIN SCRIPT_LINES "\n" ${OUTPUT_STRING_VAR_NAME})
  message(STATUS "\n${${OUTPUT_STRING_VAR_NAME}}")
endfunction()
