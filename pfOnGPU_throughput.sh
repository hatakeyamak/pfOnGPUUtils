#!/bin/bash -ex

# default configuration
SHOW_HELP=false
OUTPUT_DIR=tmp
USE_DATA=0
BENCHMARK_EXE="${CMSSW_BASE}"/../../patatrack-scripts/benchmark
BENCHMARK_EVENTS=1000
BENCHMARK_JOBS=8
BENCHMARK_THREADS=8

# help message
usage() {
  cat <<@EOF
Usage:
  This script produces configuration files, and runs throughput estimates,
  for offloading of PFRecHits and PFClustering to GPU.
  Throughput estimates are done with the executable patatrack-scripts/benchmark.

Options:
  -h, --help            Show this help message
  -o, --output-dir      Path to output directory                          [Default: ${OUTPUT_DIR}]
  -d, --data            Use Run-3 data instead of MC                      [Default: ${USE_DATA}]
  -b, --benchmark-exe   Path to patatrack-scripts/benchmark executable    [Default: ${BENCHMARK_EXE}]
  -e, --events          Throughput estimates: number of events            [Default: ${BENCHMARK_EVENTS}]
  -j, --jobs            Throughput estimates: number of jobs              [Default: ${BENCHMARK_JOBS}]
  -t, --threads         Throughput estimates: number of threads per job   [Default: ${BENCHMARK_THREADS}]
@EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) SHOW_HELP=true; shift;;
    -o|--output-dir) OUTPUT_DIR=$2; shift; shift;;
    -d|--data) USE_DATA=1; shift;;
    -b|--benchmark-exe) BENCHMARK_EXE=$2; shift; shift;;
    *) shift;;
  esac
done

# print help message and exit
if [ ${SHOW_HELP} == true ]; then
  usage
  exit 0
fi

# exit if output directory already exists
if [ -d "${OUTPUT_DIR}" ]; then
  printf "%s\n" "ERROR: target output directory already exists: ${OUTPUT_DIR}"
  exit 1
fi

# create output directory and move to it
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

###
### build cmsDriver command with options common to all wfs
###
CMSDRIVER_COMMON_CMD="cmsDriver.py step3 --geometry DB:Extended"
# don't execute config, run on 1000 events by default
CMSDRIVER_COMMON_CMD+=" --no_exec -n 10"
# local and global HCAL reconstruction from RAW (use of CPU or GPU is controlled by procModifiers, see wfs down below)
CMSDRIVER_COMMON_CMD+=" --step RAW2DIGI:RawToDigi_hcalOnly,RECO:reconstruction_hcalOnly"
# add customisation for profiling (adds consumer of particleFlowClusterHBHE)
CMSDRIVER_COMMON_CMD+=" --customise RecoLocalCalo/Configuration/customizeHcalOnlyForProfiling.customizeHcalPFOnlyForProfilingGPUOnly"

if [ "${USE_DATA}" -eq 1 ]; then
  CMSDRIVER_COMMON_CMD+=" --data --era Run3 --conditions 124X_dataRun3_v9 --scenario pp --datatier RECO --eventcontent RECO"
  # add customisation used in Run-3 RelVals (but actually, this customisation does nothing)
  CMSDRIVER_COMMON_CMD+=" --customise Configuration/DataProcessing/RecoTLR.customisePostEra_Run3"
  # copy cff with source holding Run2022 data files in .raw format
  cp /gpu_data/store/data/Run2022C/HLTPhysics/FED/v1/run357329_cff.py .
else
  # run with same GT as used for MC production (see name of EDM file)
  CMSDRIVER_COMMON_CMD+=" --mc --era Run3 --conditions 125X_mcRun3_2022_realistic_v3 --datatier RECO --eventcontent RECOSIM"
  CMSDRIVER_COMMON_CMD+=" --filein root://eoscms.cern.ch//eos/cms/store/relval/CMSSW_12_5_0_pre5/RelValTTbar_14TeV/\
GEN-SIM-DIGI-RAW/PU_125X_mcRun3_2022_realistic_v3-v2/10000/314f66c0-136e-45c2-87ba-51f496879df1.root"
fi

###
### custom.py: customisations common to all configuration files
###
cat <<@EOF > custom.py
# bugfix to customizeHcalPFOnlyForProfilingGPUOnly
process.consumer.eventProducts = ['particleFlowClusterHBHEOnly']

if 'FastTimerService' in process.__dict__:
    del process.FastTimerService
process.load("HLTrigger.Timer.FastTimerService_cfi")
process.FastTimerService.printEventSummary = False
process.FastTimerService.printRunSummary   = False
process.FastTimerService.printJobSummary   = True
process.FastTimerService.writeJSONSummary  = True
process.FastTimerService.jsonFileName = 'resources.json'
process.FastTimerService.enableDQM = False # disable DQM plots
process.MessageLogger.FastReport = cms.untracked.PSet()

#process.ThroughputService = cms.Service( "ThroughputService",
#  eventRange = cms.untracked.uint32( 10000 ),
#  eventResolution = cms.untracked.uint32( 1 ),
#  printEventSummary = cms.untracked.bool( True ),
#  enableDQM = cms.untracked.bool( False ),
##  dqmPathByProcesses = cms.untracked.bool( False ),
##  dqmPath = cms.untracked.string( "HLT/Throughput" ),
##  timeRange = cms.untracked.double( 60000.0 ),
##  timeResolution = cms.untracked.double( 5.828 )
#)
#process.MessageLogger.ThroughputService = cms.untracked.PSet()

process.options.numberOfThreads = 32
process.options.numberOfStreams = 32
process.options.wantSummary = True
@EOF

###
### CPU-only config (see step3 of wfs .521)
###
${CMSDRIVER_COMMON_CMD} --python_filename .tmp.py
echo 'process.options.accelerators = ["cpu"]' >> .tmp.py
[ "${USE_DATA}" -ne 1 ] || (echo 'process.load("run357329_cff")' >> .tmp.py)
cat custom.py >> .tmp.py
edmConfigDump .tmp.py -o hcalOnCPU_pfhbheOnCPU_cfg.py

###
### Local reco on GPU, PFRecHits+PFClusters on CPU
### (see step3 of wfs .525 + manual removal of cuda branches of PFRecHits+PFClusters)
###
${CMSDRIVER_COMMON_CMD} --python_filename .tmp.py --procModifiers gpu
echo 'process.options.accelerators = ["gpu-nvidia"]' >> .tmp.py
[ "${USE_DATA}" -ne 1 ] || (echo 'process.load("run357329_cff")' >> .tmp.py)
cat custom.py >> .tmp.py
cat <<@EOF >> .tmp.py
del process.particleFlowRecHitHBHE.cuda
del process.particleFlowRecHitHBHEOnly.cuda
del process.particleFlowClusterHBHE.cuda
del process.particleFlowClusterHBHEOnly.cuda
@EOF
edmConfigDump .tmp.py -o hcalOnGPU_pfhbheOnCPU_cfg.py

###
### GPU-only config (see step3 of wfs .525)
###
${CMSDRIVER_COMMON_CMD} --python_filename .tmp.py --procModifiers gpu
echo 'process.options.accelerators = ["gpu-nvidia"]' >> .tmp.py
[ "${USE_DATA}" -ne 1 ] || (echo 'process.load("run357329_cff")' >> .tmp.py)
cat custom.py >> .tmp.py
edmConfigDump .tmp.py -o hcalOnGPU_pfhbheOnGPU_cfg.py

###
### benchmarking
###

# run throughput estimates if patatrack-scripts/benchmark is available
if [ -f "${BENCHMARK_EXE}" ]; then
  for cfgname in hcalOnCPU_pfhbheOnCPU hcalOnGPU_pfhbheOnCPU hcalOnGPU_pfhbheOnGPU; do
    ${BENCHMARK_EXE} "${cfgname}"_cfg.py  --log "${cfgname}"_logs \
      -e "${BENCHMARK_EVENTS}" -j "${BENCHMARK_JOBS}" -t "${BENCHMARK_THREADS}" -s "${BENCHMARK_THREADS}"
  done; unset cfgname;
else
  printf "\n%s\n\n" ">>> WARNING: throughput estimates not done, path to patatrack-scripts/benchmark is invalid: ${BENCHMARK_EXE}"
fi

rm -rf __pycache__ .tmp.py
cd ..
