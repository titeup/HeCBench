#!/usr/bin/env python3
import os
import subprocess

def run_command(command, directory):
    print(f"Running command: {command} in directory: {directory}")
    os.chdir(directory)
    result = subprocess.run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode:
        print(f"Command failed with return code: {result.returncode}")
        return False
    return True

benchmarks_handled = []
if os.path.exists('bench_status.txt'):
    with open('bench_status.txt', 'r') as log_file:
        benchmarks_handled = [line.split()[0] for line in log_file.readlines()]

root_dir = os.getcwd()
for benchmark in os.listdir('src'):
    if benchmark in benchmarks_handled:
        print(f"Skipping {benchmark}")
        continue
    if benchmark.endswith('-cuda'):
        print(f"Running {benchmark}")
        bench_dir = os.path.join(root_dir, 'src', benchmark)
        status = "NOT_RUN"
        if run_command("make clean", bench_dir):
            if run_command("intercept-build make", bench_dir):
                status = "Makefile_OK"
                if run_command("dpct --gen-build-script -p=compile_commands.json --process-all --stop-on-parse-err --in-root=. --out-root=dpct_output", bench_dir):
                    status = "Conversion_OK"
                    dpct_dir = os.path.join(bench_dir, 'dpct_output')
                    if run_command("make -f Makefile.dpct", dpct_dir):
                        status = "SUCCESS"
                    else:
                        status = "NOT_COMPILED"
        os.chdir(root_dir)
        with open('bench_status.txt', 'a') as log_file:
            log_file.write(f"{benchmark} {status}\n")
