set grid
set key samplen 2 spacing .5 font ",14" noreverse enhanced autotitles nobox
set ylabel "Latency [us]"
set xlabel "Message Size [bytes]"
set style data linespoints
set term post eps enhanced color 24
set style line 1 linetype 1 lw 4 ps 2
set style line 2 linetype 2 lw 4 ps 2
set style line 3 linetype 3 lw 4 ps 2
set style line 4 linetype 4 lw 4 ps 2
set style line 5 linetype 5 lw 4 ps 2
set style line 6 linetype 6 lw 4 ps 2
set style line 7 linetype 7 lw 4 ps 2
set style line 8 linetype 8 lw 4 ps 2
set style line 9 linetype 9 lw 4 ps 2
set style line 10 linetype 1 lw 4 ps 2 lc 3
set style line 11 linetype 2 lw 4 ps 2 lc 4
set style line 12 linetype 3 lw 4 ps 2 lc 5
set xtics nomirror
set ytics nomirror
#set yrange [1:1000]
set logscale x 2
set xrange [0.25:4096]
set xtics font ",12" 
set xtics ("1K" 1,"2K" 2,"4K" 4,"8K" 8,"16K" 16,"32K" 32,"64K" 64,"128K" 128,"256K" 256,"512K" 512,"1M" 1024,"2M" 2048,"4M" 4096) font ",16" 
set key right bottom
set logscale y 2
set key width -4
plot \
"memput/mpi.dat" using ($1/1024):(($2+$3+$4+$5)/4) title "MPI" w lp ls 3,\
"memput/photon.dat" using ($1/1024):(($2+$3+$4+$5)/4) title "Photon" w lp ls 4

