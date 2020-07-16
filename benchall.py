import os

#run
# 
# export TRUFFLERUBYOPT='--jvm --polyglot --single-threaded --experimental-options'
# export PYTHONPATH=$(pwd)
#
#first
truffleruby = "/home/path/graalvm-ce-java11-20.1.0/bin/ruby"

tests = [10000, 10, 100, 500, 1000, 5000, 25000, 50000]

print("iterations,ruby,truffleruby,trufflerubypolyglot")
for k in tests:

    print(str(k)+",", end='', flush=True)
    for mode in range(1, 4):
        if os.path.exists("bench.txt"): os.remove("bench.txt")
        if mode == 1: os.system("ruby benchmark.rb " + str(k) + " > /dev/null")
        if mode == 2: os.system(truffleruby + " -Ilib/ benchmark.rb " + str(k) + " > /dev/null")
        if mode == 3: os.system(truffleruby + " benchmark_polyglot.rb " + str(k) + " > /dev/null")


        result = "failed"
        if os.path.exists("bench.txt"):
            with open("bench.txt") as f:
                result = f.read().strip()

        print(result, end='', flush=True)
        if mode != 3: print(',', end='', flush=True)
    print("")
    