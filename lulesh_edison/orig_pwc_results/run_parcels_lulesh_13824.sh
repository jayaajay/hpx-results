#!/bin/bash -l
#PBS -q regular
#PBS -l mppwidth=13824
#PBS -l walltime=01:00:00
#PBS -N parcels_lulesh_13824
#PBS -j oe

echo "-l mppwidth=13824"

export LD_LIBRARY_PATH=$HOME/psaap_perf/hpx5/lib:$HOME/psaap_perf/hpx5/lib64:$LD_LIBRARY_PATH
module unload PrgEnv-intel 
module load PrgEnv-gnu
#module load craype-hugepages8M 

cd $HOME/psaap_perf/hpx-apps
python scripts/run_lulesh.py -n 13824 -x 48 -i 500 -c 24 -j aprun
