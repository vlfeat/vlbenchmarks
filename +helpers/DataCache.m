classdef DataCache
% DATACACHE Cache data into files
%   Implementation of general data caching into files. Data are addressed
%   by unique string 'key' and are stored in the file system.
%
%   The data are stored in path DataCache.dataPath and when the size of
%   all sizes exceeds allowed size DataCache.dataPath the last recently
%   used data are removed.
%
%   When DataCache.lock = true the storage tries to be thread safe
%   however critical section is implemented as creation of empty file
%   which does not prevent all collisions.
%
%   PROPERTIES (Constant)
%     maxDataSize - Maximal storage space occupied by the cache data
%       in Bytes.
%     dataPath - Directory where to store cached data
%     dataFileVersion - Version of the .mat file used for data storage
%     autoClear - Check whether storage size has not exceeded the allowed
%       size after each storeData call when true. If so, the oldest data
%       are removed
%     disabled - disable caching when true
%
%   METHODS (Static)
%     data = getData(key) - Get data from the cache indexed by string
%       key. If the data has not been found, returns [];
%     storeData(data, key) - Store data identified by key.
%     hasData(key) - Check whether data are cached
%     removeData(key) - Remove data from the cache.
%     clearCache() - Check the overall size of the cached data and delete
%       last recently used data if exceeds.
%     deleteAllCachedData() - Delete all cached data.
%     disableAutoClear() - temporarily disable autoclear. Cannot be called
%       in parallel function.
%     enableAutoClear() - enable autoClear after disableAutoClear. Cannot
%       be called in parallel function.

% Author: Karel Lenc

% AUTORIGHTS
  properties (Constant)
    maxDataSize = 2000*1024^2; % Max. size of data in cache in Bytes
    dataPath = fullfile(pwd,'data','cache',''); % Cached data storage
    dataFileVersion = '-V7.3'; % Version of the .mat files stored
    autoClear = false; % Clear data cache automatically
    disabled = false; % Disable caching
  end

  properties (Constant, Hidden)
    % Path to file which represents temporary disabled auto clear.
    LockFileName = fullfile(helpers.DataCache.dataPath,'.lock');
  end

  methods (Static)
    function data = getData(key)
      % DATA = getData(KEY) Get DATA from the cache indexed by string KEY.
      %   If the data has not been found, returns DATA = [];
      import helpers.DataCache;
      if DataCache.disabled, data = []; return; end
      dataFile = DataCache.buildDataFileName(key);

      if exist(dataFile,'file')
        try
          packedData = load(dataFile,'packedData');
          packedData = packedData.packedData;
          if packedData.key == key
            DataCache.updateModificationDate(dataFile);
            data = packedData.data;
          else
            warning('Data collision for %s',key);
            DataCache.removeData(key);
            data = [];
          end
        catch err
          warning('Invalid data for key %s:\n%s',key,getReport(err));
          DataCache.removeData(key);
          data = [];
        end
      else
        data = [];
      end
    end

    function res = hasData(key)
      % DATA = hasData(KEY) Check whether data cached with KEY are present
      %   in the cache. Does not load the data from cache
      import helpers.DataCache;
      if DataCache.disabled, data = []; return; end
      dataFile = DataCache.buildDataFileName(key);

      res = exist(dataFile,'file');
    end

    function storeData(data, key)
      % storeData(DATA,KEY) - Store data DATA identified by key KEY.
      import helpers.DataCache;
      import helpers.*;
      dataFile = DataCache.buildDataFileName(key);
      
      if ~exist(DataCache.dataPath,'dir')
        vl_xmkdir(DataCache.dataPath);
      end
      
      packedData.key = key;
      packedData.data = data;
      
      save(dataFile,'packedData',DataCache.dataFileVersion);
      
      if DataCache.autoClearEnabled()
        DataCache.clearCache();
      end
    end

    function removeData(key)
      % removeData(KEY) - Remove data defined by KEY from the cache.
      import helpers.DataCache;
      dataFile = DataCache.buildDataFileName(key);
      if exist(dataFile,'file')
        delete(dataFile);
      else
        warning(strcat('Cache data file for key ', key, ...
          'cannot be deleted (', dataFile, ').'));
      end
    end

    function clearCache()
      %clearCache() - Check the overall size of the cached data and delete
      %   last recently used data if it exceeds the allowed size 
      %   DataCache.maxDataSize.
      import helpers.DataCache;
      maxDataSizeBytes = DataCache.maxDataSize;
      
      dataFiles = dir(fullfile(DataCache.dataPath,'*.mat'));
      dataModDates = [dataFiles.datenum];
      dataSizes = [dataFiles.bytes];
      dataNames = {dataFiles.name};
      
      [tmp order] = sort(dataModDates,'descend');
      
      sortedDataSizes = dataSizes(order);
      sortedDataNames = dataNames(order);
      
      sumDataSizes = cumsum(sortedDataSizes);
      
      filesToDelete = sortedDataNames(sumDataSizes > maxDataSizeBytes);
      
      if ~isempty(filesToDelete)
        fprintf('Deleting the oldest %d files from cache...\n',numel(filesToDelete));
        for fileName=filesToDelete
          delete(fullfile(DataCache.dataPath,fileName{:}));
        end
      end
    end

    function deleteAllCachedData()
      % deleteAllCachedData() Delete all cached data
      import helpers.*;
      fprintf('Deleting all cached data...\n');
      delete(fullfile(DataCache.dataPath,'*.mat'));
    end

    function disableAutoClear()
      % disableAutoClear() Temporarily disable cache auto clear.
      %   If DataCache.autoClear = false, this function has no effect. This
      %   function cannot be called in parallel part of the code.
      import helpers.DataCache;
      if DataCache.autoClear
        % Create lock file.
        lockFile = fopen(DataCache.LockFileName,'w');
        fclose(lockFile);
      end
    end

    function enableAutoClear()
      % enableAutoClear() Enable auto clear after calling disableAutoClear.
      import helpers.DataCache;
      if exist(DataCache.LockFileName,'file')
        delete(DataCache.LockFileName); 
      end
    end
  end

  methods (Static, Access=protected, Hidden)
    function dataFile = buildDataFileName(key)
      import helpers.*;
      hash = CalcMD5.CalcMD5(key);
      dataFile = fullfile(DataCache.dataPath,strcat(hash,'.mat'));
    end
    
    function updateModificationDate(fileName)
      helpers.touch(fileName);
    end

    function doClear = autoClearEnabled()
      import helpers.DataCache;
      doClear = DataCache.autoClear && ~exist(DataCache.LockFileName,'file');
    end
  end
end
