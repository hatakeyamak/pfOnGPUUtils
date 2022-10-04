These instructions are work-in-progress.
```sh
git clone git@github.com:missirol/patatrack-scripts.git -o missirol -b devel_benchmarkWithArgparse
scram project CMSSW CMSSW_12_5_0
cd CMSSW_12_5_0/src
eval `scram runtime -sh`
git cms-init --ssh
git cms-merge-topic missirol:PFGPU_hackathon_1
scram build -j 8
git clone git@github.com:missirol/pfOnGPUUtils.git -o missirol -b master
./pfOnGPUUtils/pfOnGPU_throughput.sh --help
./pfOnGPUUtils/pfOnGPU_throughput.sh -o tmp -d -e 1000 -j 2 -t 2
```
