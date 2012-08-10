classdef genericBenchmark < handle
  %GENERICTEST Generic test of affine covariant detector.
  %   genericTest(framesStorage, test_name,'Option','OptionValue',...)
  %   This class implements mutual parts of affine covariant
  %   detectors test.
  
  properties
    test_name         % Name of the test shown in the results
  end
  
  methods (Abstract)
    
  end
  
  methods
    
    function obj=genericTest(test_name)
      obj.test_name = test_name;
    end
    
  end
  
end

