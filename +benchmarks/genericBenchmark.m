classdef genericBenchmark < handle & helpers.Logger
  %GENERICBENCHMARK Generic test of affine covariant detector.
  %   genericTest(framesStorage, test_name,'Option','OptionValue',...)
  %   This class implements mutual parts of affine covariant
  %   detectors test.
  
  properties
    benchmarkName         % Name of the test shown in the results
  end
 
  
  methods
    signature = getSignature(obj)
    % GETSIGNATURE Get signature of the benchmark settings
  end
end

