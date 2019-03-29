function(generate_data_gathering_unix OUTPUT_LIST BENCH_INPUT_NAME)
  string(TOUPPER ${BENCH_INPUT_NAME} BENCH_NAME)
  string(TOLOWER ${BENCH_NAME} BENCH_LOWER_NAME)
  list(LENGTH ${BENCH_NAME}_DATA_COLUMN_NAME RN_LENGTH)
  list(LENGTH ${BENCH_NAME}_DATA_EXTRACT_FN RE_LENGTH)
  list(JOIN ${BENCH_NAME}_BENCH_TARGET_LIST " " BENCH_TARGETS_STRING)
  if (NOT (RN_LENGTH EQUAL RE_LENGTH))
    message(FATAL_ERROR "The list of data to extract (${BENCH_NAME}_DATA_COLUMN_NAME) and command used to extract them (${BENCH_NAME}_DATA_EXTRACT_FN) must be of same size")
  endif()
  set(SCRIPT_LIST "# Start ${BENCH_LOWER_NAME} data gathering script\n")
  if (RN_LENGTH EQUAL "0")
    list(APPEND SCRIPT_LIST
      "printf \"\\n[$\{cian_color\}BENCH INFO$\{reset_color\}] Application ${BENCH_LOWER_NAME} did not set gathering commands (${BENCH_NAME}_DATA_EXTRACT_FN) nor the list of data to extract (${BENCH_NAME}_DATA_COLUMN_NAME), skipping...\\n\"")
  else()
    math(EXPR RN_LENGTH "${RN_LENGTH}-1")
    list(APPEND SCRIPT_LIST
      "printf \"\\n[$\{cian_color\}BENCH INFO$\{reset_color\}] Gathering results from bench ${BENCH_LOWER_NAME}\\n\""
      "mkdir -p $(dirname ${${BENCH_NAME}_GATHER_LOCATION})"
      "printf \"Bench\" > ${${BENCH_NAME}_GATHER_LOCATION}"
      "printf \"  Gathering data (\""
      )
    foreach(iterator_val IN LISTS ${BENCH_NAME}_DATA_COLUMN_NAME)
      list(APPEND SCRIPT_LIST
        "printf \" ${iterator_val}\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
        "printf \" ${iterator_val}\""
        )
    endforeach()
    list(APPEND SCRIPT_LIST
      "printf \"\\n\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
      "printf \" ) from folders:\\n\""
      "current_bench_dirname=\"$(dirname ${${BENCH_NAME}_RESULTS_DIR})\""
      "current_bench_basename=\"$(basename ${${BENCH_NAME}_RESULTS_DIR})\""
      "find \"$current_bench_dirname\" -regex \".*$current_bench_basename-[1-9][0-9]*\" | while read dirname"
      "do"
      "  bench_result_location=\"$dirname\""
      "  printf \"    - $\{magenta_color\}$dirname$\{reset_color\}\\n\""
      "  for bench_name in ${BENCH_TARGETS_STRING}"
      "  do"
      "    printf \"$bench_name\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
      )

    foreach(iterator_val RANGE 0 ${RN_LENGTH})
      list(GET ${BENCH_NAME}_DATA_EXTRACT_FN ${iterator_val} EXTRACT_COMMAND)
      list(GET ${BENCH_NAME}_DATA_COLUMN_NAME ${iterator_val} DATA_NAME)
      list(APPEND SCRIPT_LIST
        "    extracted_value=$((${EXTRACT_COMMAND}) | tr -d \"\\n\")"
        "    if [ \"x$extracted_value\" = x ]"
        "    then"
        "      printf \" NO_VAL_${DATA_NAME}\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
        "    else"
        "      printf \" $extracted_value\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
        "    fi"
        )
    endforeach()

    list(APPEND SCRIPT_LIST
      "    printf \"\\n\" >> ${${BENCH_NAME}_GATHER_LOCATION}"
      "  done"
      "done"
      "printf \"  Results are available in the file $\{magenta_color\}${${BENCH_NAME}_GATHER_LOCATION}$\{reset_color\}\\n\""
      )
  endif()
  list(APPEND SCRIPT_LIST "\n# End ${BENCH_LOWER_NAME} data gathering script")
  set(${OUTPUT_LIST} ${SCRIPT_LIST} PARENT_SCOPE)
endfunction()
