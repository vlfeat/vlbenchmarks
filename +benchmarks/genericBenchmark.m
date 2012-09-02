classdef genericBenchmark < handle
  %GENERICBENCHMARK Abstract class defining generic benchmark
  
  properties
    benchmarkName         % Name of the test
  end
 
  methods
    signature = getSignature(obj)
    % GETSIGNATURE Get signature of the benchmark settings
  end
end

