import os

#run
# 
# export TRUFFLERUBYOPT='--jvm --polyglot --single-threaded --experimental-options'
# export PYTHONPATH=$(pwd)
#
#first
truffleruby = "~/Runtimes/graalvm-ce-java11-20.1.0/bin/ruby"

tests = [i for i in range(1, 101, 1)]
PYCALL_RB, TRUFFLERUBY_PYCALL, TRUFFLERUBY_POLYGLOT = range(3)
modes = [PYCALL_RB, TRUFFLERUBY_PYCALL, TRUFFLERUBY_POLYGLOT]

print("doing ", tests)
print("iterations,ruby,truffleruby,trufflerubypolyglot")

for k in tests:
    print(str(k)+",", end='', flush=True)
    for mode in modes:
        if os.path.exists("bench.txt"):
            os.remove("bench.txt")
        if mode == PYCALL_RB:
            os.system("ruby benchmark.rb " + str(k) + " > /dev/null")
        if mode == TRUFFLERUBY_POLYGLOT:
            os.system(truffleruby + " -Ilib/ benchmark.rb " + str(k) + " > /dev/null")
        if mode == TRUFFLERUBY_PYCALL:
            os.system(truffleruby + " benchmark_polyglot.rb " + str(k) + " > /dev/null")
        result = "failed"
        if os.path.exists("bench.txt"):
            with open("bench.txt") as f:
                result = f.read().strip()
        print(result, end='', flush=True)
        if mode != 3: print(',', end='', flush=True)
    print("")
    