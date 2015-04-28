#!/bin/bash -l
#PBS -q regular
#PBS -l mppwidth=19683
#PBS -l walltime=02:00:00
#PBS -N parcels_lulesh_19683
#PBS -j oe

echo "-l mppwidth=19683"

export LD_LIBRARY_PATH=$HOME/psaap_perf/hpx5/lib:$HOME/psaap_perf/hpx5/lib64:$LD_LIBRARY_PATH
module unload PrgEnv-intel 
module load PrgEnv-gnu
#module load craype-hugepages8M 

cd $HOME/psaap_perf/hpx-apps
python scripts/run_lulesh.py -n 19683 -x 48 -i 500 -c 24 -j aprun
