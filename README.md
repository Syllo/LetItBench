Leverage Estimate by Transforming Inexact-Tough Benchmarks (LetItB)
===================================================================

LetItB provides a set of non-optimized and approximation-resilient application which can be targeted by automatic tools to leverage the approximation
opportunities that they offer.

Table of Contents
-----------------

1. [Requirements](#requirements)
1. [Benchmarks](#benchmarks)
  1. [Benchmarks Configuration](#benchmarks-configuration)
  1. [Run the Benchmarks](#run-the-benchmarks)

Requirements
------------

- A recent version of CMake (>=3.12):
  - Most linux distribution provides a CMake package (may be an outdated version).
  - Pre-build binaries for multiple systems can be downloaded from the [cmake website](https://cmake.org/download/).
- GNU make

Benchmarks
----------

The benchmarks configuration resides in the `LetItB/benchmarks_configuration` folder.
This folder contains:

- `MasterConfig.cmake`
  - Set the variable `COMMON_BATCH_NUM` to configure the number of runs.
  - Set the list `COMMON_BENCH_COMPILE_OPTION` to the relevant compilation options.
  - Set the list `COMMON_BENCH_LINK_OPTION` to the relevant linker options.
  - Set the list `BENCHMARK_SET` to point to a new application configuration file to add a new application.
- `<ApplicationName>.cmake`
  - Set the list `*_COMPILE_OPTIONS` to override the common compilation options.
  - Set the list `*_LINK_OPTIONS` to override the common compilation options.
  - Uncomment `*_BATCH_NUM` to override the number of batch runs for this application.
  - Create new run by creating a list starting with its name and followed by the application parameters.
  - Disable / Enable runs by removing / adding a run (application parameters) to the `*_BENCHMARKS` list.

### Run the Benchmarks

Follow the following instructions in a terminal:

```bash
git clone https://github.com/Syllo/LetItB.git
mkdir -p LetItB/build && cd LetItB/build
cmake ..
make bench       # To run only one time
make batch-bench # To run the benchmarks multiple times in a row (see Benchmarks Configuration)
```

The results will be available in the directory `LetItB/benchmarks_result_directory`.
