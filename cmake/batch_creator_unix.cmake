function(generate_batch_for_bench_unix OUTPUT_LIST BENCH_INPUT_NAME)
  string(TOUPPER ${BENCH_INPUT_NAME} BENCH_NAME)
  string(TOLOWER ${BENCH_NAME} BENCH_LOWER_NAME)
  set(SCRIPT_LIST "# Start ${BENCH_LOWER_NAME} batch definition\n")
  if(${${BENCH_NAME}_BATCH_NUM} GREATER 0)
    list(JOIN ${BENCH_NAME}_BENCH_TARGET_LIST " " THIS_BENCH_TARGET_STRING)
    list(APPEND SCRIPT_LIST
      "printf \"[$\{magenta_color\}BENCH BATCH$\{reset_color\}] Proceeding with batch for ${BENCH_LOWER_NAME} (${${BENCH_NAME}_BATCH_NUM} runs)\\n\""
      "for i in ${THIS_BENCH_TARGET_STRING}"
      "do"
      "  echo \"    - $i\""
      "done"
      "printf \"\\n\""
      "n_batch=1"
      "while [ $n_batch -le ${${BENCH_NAME}_BATCH_NUM} ]"
      "do"
      "  printf \"[$\{cian_color\}BENCH RUN$\{reset_color\}] Running bench set for application ${BENCH_LOWER_NAME} ($n_batch/${${BENCH_NAME}_BATCH_NUM})\\n\\n\""
      "  ${CMAKE_COMMAND} --build ${PROJECT_BINARY_DIR} --target ${${BENCH_NAME}_RUN_BENCHMARKS_AND_MOVE_TARGET}"
      "  n_batch=$((n_batch+1))"
      "  printf \"\\n\""
      "done"
      )
  else()
    list(APPEND SCRIPT_LIST
      "printf \"\\n[$\{magenta_color\}BENCH BATCH$\{reset_color\}] Batch number for the application ${BENCH_LOWER_NAME} is set zero, skipping...\\n\\n\"")
  endif()
  list(APPEND SCRIPT_LIST "\n# End ${BENCH_LOWER_NAME} batch definition")
  set(${OUTPUT_LIST} ${SCRIPT_LIST} PARENT_SCOPE)
endfunction()
