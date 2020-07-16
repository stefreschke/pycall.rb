def benchloop(innerloop)
    pybenchmark = Polyglot.eval('python', 'import benchmark;benchmark')
    randint = rand(1..10)
    for add in 1..innerloop
        pybenchmark.add(randint)
    end
    for subtract in 1..innerloop
        pybenchmark.sub(randint)
    end
end


warmup = RUBY_ENGINE == "truffleruby" ? 10000 : 100 #pycall crashes with too much iterations
puts "Warming up..."
for i in 1..warmup
    benchloop(1500)
end
puts "Warmup done."


innerloop = ARGV[0].to_i
#measure time
starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
for i in 1..1000
    benchloop(innerloop)
end
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Benchmark Time:"
puts elapsed
File.open("bench.txt", "w") { |f| f.write elapsed.to_s }