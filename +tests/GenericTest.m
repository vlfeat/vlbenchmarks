classdef GenericTest < helpers.Logger & helpers.GenericInstaller
  
  properties
    GTOpts = struct(...
      'hardFail',true ...
      );
  end
  
  methods
    
    function varargin = configureGenericTest(obj, testName, varargin)
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(testName,varargin);
      [obj.GTOpts varargin] = vl_argparse(obj.GTOpts, varargin);
    end
    
    testAll(obj)
    
    function assertTrue(obj, message, condition)
      if ~condition
        obj.fail(message);
      end
    end
    
    function assertEqual(obj, testName, expected, actual, tolerance)
      if nargin < 5
        tolerance = 0;
      end
      
      obj.info(sprintf(['Test "%s"\nExp. values:\t%s\nAct. values:\t%s\n', ...
        'Diff:       \t%s\nTolerance:\t%10.2f'], ...
        testName, ...
        sprintf('%10.2f  ',expected), ...
        sprintf('%10.2f  ',actual), ...
        sprintf('%10.2f  ',abs(expected - actual)), ...
        tolerance))
      
      if any(abs(expected - actual) > tolerance)
        obj.fail(sprintf('Test "%s" failed.',testName));
      end
    end
    
    function assertMaxError(obj, testName, error, tolerance)
      if nargin < 4
        tolerance = 0;
      end
      
      obj.info(sprintf('Test "%s"\nError:\t%s\nTolerance:\t%10.2f', ...
        testName, sprintf('%10.2f  ',abs(error)), tolerance));
      
      if any(abs(error) > tolerance)
        obj.fail(sprintf('Test "%s" failed.',testName));
      end
    end
    
    function fail(obj, reason)
      if obj.GTOpts.hardFail
        obj.error(reason);
      else
        obj.warn(reason);
      end
    end
  end
  
  methods (Access=protected, Hidden)
    function deps =getDependencies(obj)
      deps = {helpers.VlFeatInstaller()};
    end
  end
  
end

