#!/bin/bash

EXE_COMMON="./pfOnGPUUtils/pfOnGPU_throughput.sh -b ${CMSSW_BASE}/../../patatrack-scripts/benchmark"
EXE_COMMON+=" -d -o benchmark_8189a9f0f08/data"

#${EXE_COMMON}/t01_j64 -t  1 -j 64 -e 1024
#${EXE_COMMON}/t02_j32 -t  2 -j 32 -e 1024
#${EXE_COMMON}/t04_j16 -t  4 -j 16 -e 1024
#${EXE_COMMON}/t08_j08 -t  8 -j  8 -e 1024
#${EXE_COMMON}/t16_j04 -t 16 -j  4 -e 1024
#${EXE_COMMON}/t32_j02 -t 32 -j  2 -e 1024
#${EXE_COMMON}/t64_j01 -t 64 -j  1 -e 1024

#${EXE_COMMON}/t02_j01 -t  2 -j  1 -e 1024
#${EXE_COMMON}/t08_j01 -t  8 -j  1 -e 1024
${EXE_COMMON}/t08_j08_2 -t  8 -j  8 -e 1024
