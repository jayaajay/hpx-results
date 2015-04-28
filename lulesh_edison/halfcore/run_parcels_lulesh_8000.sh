#!/bin/bash -l
#PBS -q regular
#PBS -l mppwidth=8000
#PBS -l walltime=02:00:00
#PBS -N parcels_lulesh_8000
#PBS -j oe

echo "-l mppwidth=8000"

export LD_LIBRARY_PATH=$HOME/psaap_perf/hpx5/lib:$HOME/psaap_perf/hpx5/lib64:$LD_LIBRARY_PATH
module unload PrgEnv-intel 
module load PrgEnv-gnu
#module load craype-hugepages8M 

cd $HOME/psaap_perf/hpx-apps
python scripts/run_lulesh2.py -n 8000 -x 48 -i 100 -c 24 -j aprun