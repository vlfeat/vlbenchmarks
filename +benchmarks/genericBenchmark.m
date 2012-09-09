classdef genericBenchmark < handle
%  GENERICBENCHMARK The base class of a benchmark

  properties
    benchmarkName % Name of the benchmark
  end

  properties(GetAccess=public, SetAccess = protected)
    useCache = true;
  end

  methods (Abstract)
    signature = getSignature(obj)
    % GETSIGNATURE Get a signature (hash) identifying the benchmark settings
  end

  methods
    function enableCaching(obj)
      % ENABLECACHING Enable caching of results
      obj.useCache = true;
    end

    function disableCaching(obj)
      % DISABLECACHING Disable caching of results
      obj.useCache = false;
    end
  end

  methods (Access=protected)
    function cachedResults = loadResults(obj,resultsKey)
      import helpers.*;
      if obj.useCache
        cachedResults = DataCache.getData(resultsKey);
      else
        cachedResults = [];
      end
    end

    function storeResults(obj, results, resultsKey)
      import helpers.*;
      if ~obj.useCache, return; end;
      helpers.DataCache.storeData(results, resultsKey);
    end
  end
end

