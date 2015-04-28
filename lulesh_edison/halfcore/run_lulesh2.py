import math
import os
import subprocess
import sys

HOME = os.path.expanduser("~")

### Parameters

job_launcher = 'mpirun_1_8'
num_phys_cores = 16
hyperthread = False
path_hpx_exe = './lulesh/parcels/luleshparcels'
path_mpi_exe = './lulesh/mpi/luleshMPI'

outfile = 'results.xml'
lulesh_n = 64
lulesh_x = 48
lulesh_i = 500
iters_per_size = 5

###

def markup(tag_name, contents):
    return '&lt;' + tag_name + '&gt;' + contents + '&lt;/' + tag_name + '&gt;'

def write_measurement(f, name, value):
    s = markup('measurement', markup('name', name) + markup('value', str(value)))
    f.write(s + '\n')
    return

def write_junit_out(fail, n, x, i, iters_per_size, avg, comptime, filename='results.xml'):
    f = open(filename, 'w')
    f.write('<testsuite tests=\"1\">\n')
    f.write('<testcase classname=\"lulesh\" ' + 
            'name=\"' + str(n * x ** 3) + '_' + str(i) + '\" ' +
            'time=\"' + str(avg) + '\">\n')
    if (fail):
        f.write('<failure type=\"generic\">FAIL</failure>')
    else:
       # for format see:
       # https://wiki.jenkins-ci.org/display/JENKINS/Measurement+Plots+Plugin
       f.write('<system-out>\n')
       write_measurement(f, 'MPI over (hpx average)', comptime/(1.0 * avg))
       write_measurement(f, 'average time (s)', avg)
       write_measurement(f, 'MPI time (s)', comptime)
       write_measurement(f, 'points', n * x ** 3)
       write_measurement(f, 'iterations', i)
       write_measurement(f, 'runs average over', iters_per_size)
       f.write('</system-out>\n')
    f.write('</testcase>\n')
    f.write('</testsuite>\n')
    f.close()
    return

def get_topology(ht, n):
    # how many cores should we use per node? (hyperthread yes or no)
    cores_per_node = num_phys_cores
    if hyperthread:
        cores_per_node = cores_per_node * 2
    # how many nodes? given lulesh domains and cores per node
    nodes = int(math.ceil(n/ (cores_per_node*1.0)))
    return (nodes, cores_per_node)

def get_run_command_hpx(ht, n, x, i, network="pwc"):
    nodes, cores_per_node = get_topology(ht, n)
    cores_per_node = cores_per_node/2
    print "HPX nodes, cores_per_node = ", nodes, cores_per_node

    run_command = []
    # TODO: parameterize run commands (slurm vs torque, say)
    if job_launcher == 'aprun':
        run_command = ['aprun', '-n', str(nodes), '-N', '1', '-d', str(cores_per_node)]
        if ht:
            run_command += ['-j', str(0)]
    elif job_launcher == 'mpirun_1_6':
        run_command = ['mpirun', '-np', str(nodes), '-bynode', '-cpus-pre-proc=' + str(cores_per_node)]
    elif job_launcher == 'mpirun_1_8':
        run_command = ['mpirun', '-np', str(nodes), '--map-by', 'node:PE=' + str(cores_per_node)]
    elif job_launcher == 'mvapich':
        run_command = ['ibrun', '-np', str(nodes)]
    else:
        print "ERROR: could not set job launcher from input {", job_launcher, "}"
        sys.exit(1)

    run_command += [str(path_hpx_exe), '--hpx-threads=' + str(cores_per_node), '--hpx-network=' + network]
    run_command += ['-n', str(n), '-x', str(x), '-i', str(i)]

    return run_command

def get_run_command_mpi(ht, n, x, i):
    # TODO: parameterize run commands (slurm vs torque, say)
    cores_per_node = num_phys_cores
    print "MPI cores_per_node = ", cores_per_node

    if job_launcher == 'aprun':
        if ht:
            cores_per_node = cores_per_node * 2
        run_command = ['aprun', '-n', str(n), '-N', str(cores_per_node), '-d', str(1)]
        if ht:
            run_command += ['-j', str(0)]
    elif job_launcher == 'mpirun_1_6':
        run_command = ['mpirun', '-np', str(n)]
    elif job_launcher == 'mpirun_1_8':
        run_command = ['mpirun', '-np', str(n)]
    elif job_launcher == 'mvapich':
        run_command = ['ibrun', '-np', str(n)]
    else:
        print "ERROR: could not set job launcher from input {", job_launcher, "}"
        sys.exit(1)
    
    run_command += [path_mpi_exe]
    run_command += [str(x), str(i)]
    return run_command


def get_num_from_string(str, si, substr):
    i = str.find(substr, si)
    if i > 0:
        i += len(substr)
    nexti = str.find('\n', i)
    try:
        val = float(str[i:nexti])
        return (val, nexti)
    except:
        return (0.0, nexti)

def process_output(sout, serr):
    elapsed, nexti = get_num_from_string(sout, 0, 'Elapsed time = ')
    energy, nexti = get_num_from_string(sout, nexti, 'Final Origin Energy = ')
    diff1, nexti  = get_num_from_string(sout, nexti, 'MaxAbsDiff   =')
    diff2, nexti  = get_num_from_string(sout, nexti, 'TotalAbsDiff =')
    diff3, nexti  = get_num_from_string(sout, nexti, 'MaxRelDiff   =')
    return (elapsed, energy, diff1, diff2, diff3)

def invalid(num):
    return num == 0.0 or math.isnan(num) or math.isinf(num)

def run_lulesh_instance(run_command):
    error = False
    try:
        p = subprocess.Popen(run_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        sout, serr = p.communicate()
        if p.returncode != 0:
            error = True
        print sout
        print serr
        (elapsed, final, diff1, diff2, diff3) = process_output(sout, serr)
        print elapsed, final, diff1, diff2, diff3
        if invalid(final) or invalid(diff1) or invalid(diff2) \
           or invalid(diff3):
            error = True
            print "FAIL: invalid results in", (final, diff1, diff2, diff3)
        if error is True:
            return (True, 0, 0)
    except:
        print "ERROR: when running ", run_command
        return (True, 0, 0)
    return (error, elapsed, final)

def run_lulesh_size(domains):
    run_command_hpx_pwc = get_run_command_hpx(hyperthread,
                                              lulesh_n, lulesh_x, lulesh_i, 'pwc')
    run_command_hpx_isir = get_run_command_hpx(hyperthread,
                                               lulesh_n, lulesh_x, lulesh_i, 'isir')
    run_command_mpi = get_run_command_mpi(hyperthread,
                                          lulesh_n, lulesh_x, lulesh_i)

    elapseds = [0] * iters_per_size
    for i in xrange(0, iters_per_size):
        print "mpi",
        (error, elapsed, compval) = run_lulesh_instance(run_command_mpi)
        if error:
            print "ERROR: Error when running MPI with " + ' '.join(run_command_mpi)
        else:
            elapseds[i] = elapsed
    command_str = ' '.join(run_command_mpi)
    print 'Command = {' + command_str + '}'
    avg = math.fsum(elapseds) / iters_per_size
    comptime = avg
    if error:
        print "ERROR: Bad results or problem running MPI lulesh"
    else:
        avg = math.fsum(elapseds) / iters_per_size
        print 'Average for MPI over ', iters_per_size, ' = ', avg

    elapseds = None
    elapseds = [0] * iters_per_size
    for i in xrange(0, iters_per_size):
        print "hpx-isir",
        (error, elapsed, value) = run_lulesh_instance(run_command_hpx_isir)
        if value != compval:
            error = True
            print "FAIL: ", value, " != ", compval
        if error:
            break
        else:
            elapseds[i] = elapsed
    command_str = ' '.join(run_command_hpx_isir)
    print 'Command = {' + command_str + '}'
    avg = math.fsum(elapseds) / iters_per_size
    if error:
        print "ERROR: Bad results or problem running lulesh"
    else:
        avg = math.fsum(elapseds) / iters_per_size
        print 'HPX ISIR Average over ', iters_per_size, ' = ', avg
        print 'HPX ISIR Ratio of (MPI time)/(hpx time) = ', comptime/avg

    elapseds = None
    elapseds = [0] * iters_per_size
    for i in xrange(0, iters_per_size):
        print "hpx-pwc",
        (error, elapsed, value) = run_lulesh_instance(run_command_hpx_pwc)
        if value != compval:
            error = True
            print "FAIL: ", value, " != ", compval
        if error:
            break
        else:
            elapseds[i] = elapsed
    command_str = ' '.join(run_command_hpx_pwc)
    print 'Command = {' + command_str + '}'
    avg = math.fsum(elapseds) / iters_per_size
    write_junit_out(error, lulesh_n, lulesh_x, lulesh_i, iters_per_size, avg, comptime, outfile)
    if error:
        print "ERROR: Bad results or problem running lulesh"
    else:
        avg = math.fsum(elapseds) / iters_per_size
        print 'HPX PWC  Average over ', iters_per_size, ' = ', avg
        print 'HPX PWC  Ratio of (MPI time)/(hpx time) = ', comptime/avg

if __name__ == '__main__':

    import string
    from sys import argv
    import os
    import sys
    import getopt

    opts, junk = getopt.getopt(argv[1:], "n:x:i:I:j:c:o:")
    if len(opts) > 0:
        for flag, arg in opts:
            if flag == '-n':
                lulesh_n = int(arg)
            elif flag == '-x':
                lulesh_x = int(arg)
            elif flag == '-i':
                lulesh_i = int(arg)
            elif flag == '-I':
                iters_per_size = int(arg)
            elif flag == '-j':
                job_launcher = arg.strip()
                print "Setting job launcher to ", arg
            elif flag == '-j':
                job_launcher = arg.strip()
                print "Setting job launcher to ", arg
            elif flag == '-c':
                num_phys_cores = int(arg)
            elif flag == '-o':
                outfile = arg.strip()

    domains = lulesh_n
    run_lulesh_size(domains)
