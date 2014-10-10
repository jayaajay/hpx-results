set grid
set key samplen 2 spacing .8 font ",14" noreverse enhanced autotitles nobox
set ylabel "Traversed edges per second [TEPS]"
set xlabel "Number of Nodes (16 cores per  node)"
set style data linespoints
set term pdf enhanced color
set style line 1 linetype 1 lw 4 ps 1
set style line 2 linetype 2 lw 4 ps 1
set style line 3 linetype 3 lw 4 ps 1
set style line 4 linetype 4 lw 4 ps 1
set style line 5 linetype 5 lw 4 ps 1
set style line 6 linetype 6 lw 4 ps 1
set style line 7 linetype 7 lw 4 ps 1
set style line 8 linetype 8 lw 4 ps 1
set style line 9 linetype 9 lw 4 ps 1
set style line 10 linetype 1 lw 4 ps 1 lc 3
set style line 11 linetype 2 lw 4 ps 1 lc 4
set style line 12 linetype 3 lw 4 ps 1 lc 5
set xtics nomirror
set ytics nomirror
set mxtics 2
set xrange [4:16]
#set yrange [1:1000]
set logscale x 2
set xtics (4, 6, 8, 10, 12, 14, 16) font ",14" 
set title "Chaotic label-correcting SSSP performance"
set key left top opaque
#set logscale y
plot "sssp.dat" using 1:2 title "HPX 5 (with Photon)" w lp ls 3
