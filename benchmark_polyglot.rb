#Same as benchmark.rb, but without PyCall / canilla Polyglot.eval instead

def benchloop(innerloop)
    pybenchmark = Polyglot.eval('python', 'import benchmark;benchmark')
    pybenchmark.reset()
    randint = rand(1..10)
    x = 0
    for add in 1..innerloop
        x += pybenchmark.add(randint)
    end
    for subtract in 1..innerloop
        x += pybenchmark.sub(randint)
    end
    if x != innerloop*innerloop*randint #verify solution using gaussian sum formula
        exit 
    end
    x
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
x = 0
for i in 1..1000
    x += benchloop(innerloop)
end
puts x
ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = ending - starting
puts "Benchmark Time:"
puts elapsed
File.open("bench.txt", "w") { |f| f.write elapsed.to_s }