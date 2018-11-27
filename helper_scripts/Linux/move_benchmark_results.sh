#!/bin/sh

if ! command tput 2>/dev/null 1>&2
then
  if [ $(tput colors) -ge 16 ]
  then
    cian_color="\033[36m"
    magenta_color="\033[35m"
    reset_color="\033[0m"
  fi
fi

if [ $# -ne 1 ]
then
  exit 1
fi

absolute_path="$(cd "$(dirname "$1")" || exit 1; pwd)/$(basename "$1")"

if [ -d "$1" ]
then
  value=1
  new_name="$absolute_path-$value"
  while [ -d "$new_name" ]
  do
    value=$((value+1))
    new_name="$absolute_path-$value"
  done
  printf "[${cian_color}BENCH INFO${reset_color}] Benchmark results for $(basename "$1") available in ${magenta_color}\"$new_name\"${reset_color}\\n"
  mv "$absolute_path" "$new_name"
fi
