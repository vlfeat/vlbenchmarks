classdef GenericBenchmark< handle
%  GENERICBENCHMARK The base class of a benchmark
%    Defines getSignature abstract method.
%    This base class implements only several helper methods as access to
%    cache which is blockable using methods enableCahe() and
%    disableCache().

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
      % RES = LOADRESULTS(RESULTS_KEY) Load result RES defined by 
      %   RESULTS_KEY from the cache. When no result found or 
      %   useCache=false, returned empty array.
      import helpers.*;
      if obj.useCache
        cachedResults = DataCache.getData(resultsKey);
      else
        cachedResults = [];
      end
    end

    function storeResults(obj, results, resultsKey)
      % STORERESULTS(RES, RESULTS_KEY) Store results to a cache. If
      % useCache=false, nothing is done.
      import helpers.*;
      if ~obj.useCache, return; end;
      helpers.DataCache.storeData(results, resultsKey);
    end
  end
end

