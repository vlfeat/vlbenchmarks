classdef DataCache
  %DATACACHE Cache data into files
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
  %     dataPath - Path to cached data
  %     dataFileVersion - Version of the .mat file used for data storage
  %     autoClear - Check whether storage size has not exceeded the allowed
  %       size after each storeData call when true. If so, the oldest data
  %       are removed
  %     lock - Lock cache when data being erased. However the cache is
  %       locked by writing empty file which does not get rid of all race
  %       conditions. Use carefully.
  %
  %   METHODS (Static)
  %     data = getData(key) - Get data from the cache indexed by string
  %       key. If the data has not been found, returns [];
  %     storeData(data,key) - Store data identified by key.
  %     removeData(key) - Remove data from the cache.
  %     clearCache() - Check the overall size of the cached data and delete
  %       last recently used data if exceedes.
  %     deleteAllCachedData() - Delete all cached data.
  
  properties (Constant)
    maxDataSize = 5000*1024^2; % Max. size of data in cache in Bytes
    dataPath = fullfile(pwd,'data','cache',''); % Cached data storage
    dataFileVersion = '-V7'; % Version of the .mat files stored
    autoClear = true; % Clear data cache automatically
    lockCache = false; % Prevent removal of accessed data, for SMP
    disabled = false; % Disable caching
  end
  
  methods (Static)
    
    function data = getData(key)
      % data = GETDATA(key) Get data from the cache indexed by string key.
      %   If the data has not been found, returns [];
      import helpers.DataCache;
      if DataCache.disabled, data = []; return; end
      DataCache.waitForUnlock();
      dataFile = DataCache.buildDataFileName(key);

      if exist(dataFile,'file')
        packedData = load(dataFile,'packedData');
        packedData = packedData.packedData;
        if packedData.key == key
          DataCache.updateModificationDate(dataFile);
          data = packedData.data;
        else
          warning(strcat('Data collision for ',key));
          DataCache.removeData(key);
          data = [];
        end
      else
        data = [];
      end
    end

    function storeData(data, key)
      % STOREDATA(DATA,KEY) - Store data DATA identified by key KEY.
      import helpers.DataCache;
      import helpers.*;
      DataCache.waitForUnlock();
      dataFile = DataCache.buildDataFileName(key);
      
      if ~exist(DataCache.dataPath,'dir')
        vl_xmkdir(DataCache.dataPath);
      end
      
      packedData.key = key;
      packedData.data = data;
      
      save(dataFile,'packedData',DataCache.dataFileVersion);
      
      if DataCache.autoClear
        DataCache.clearCache();
      end
    end

    function removeData(key)
      % REMOVEDATA(KEY) - Remove data defined by KEY from the cache.
      import helpers.DataCache;
      DataCache.waitForUnlock();
      dataFile = DataCache.buildDataFileName(key);
      if exist(dataFile,'file')
        delete(dataFile);
      else
        warning(strcat('Cache data file for key ', key, ...
          'cannot be deleted (', dataFile, ').'));
      end
    end

    function clearCache()
      %CLEACACHE() - Check the overall size of the cached data and delete
      %   last recently used data if it exceedes the allowed size 
      %   DataCache.maxDataSize.
      import helpers.DataCache;
      maxDataSizeBytes = DataCache.maxDataSize;
      DataCache.lock();
      
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
      DataCache.unlock();
    end

    function deleteAllCachedData()
      % DELETEALLCACHEDDATA() Delete all cached data
      import helpers.*;
      fprintf('Deleting all cached data...\n');
      delete(fullfile(DataCache.dataPath,'*.mat'));
    end
  end
  
  methods (Static, Access=protected)
    
    function dataFile = buildDataFileName(key)
      import helpers.*;
      hash = CalcMD5.CalcMD5(key);
      dataFile = fullfile(DataCache.dataPath,strcat(hash,'.mat'));
    end
    
    function updateModificationDate(fileName)
      helpers.touch(fileName);
    end
    
    function lock()
      import helpers.DataCache;
      if DataCache.lockCache
        lockFileName = strcat('.lock');
        lockFile = fopen(lockFileName,'w');
        fclose(lockFile);
      end
    end
    
    function unlock()
      import helpers.DataCache;
      if DataCache.lockCache
        lockFileName = strcat('.lock');
        if exist(lockFileName,'file')
          delete(lockFileName); 
        end
      end
    end
    
    function locked = isLocked()
      import helpers.DataCache;
      if DataCache.lock
        lockFileName = strcat('.lock');
        locked = exist(lockFileName,'file');
      else
        locked = false;
      end
    end

    function waitForUnlock()
      import helpers.*;
      if ~DataCache.lockCache, return; end;
      maxWaitTime = 10*60;
      waitTime = 0;
      fprintf('Cache locked. Waiting.\n');
      while DataCache.isLocked()
        pause(1)
        waitTime = waitTime + 1;
        if waitTime > maxWaitTime
          warning('Data cache is locked for too long. Unlock forced.');
          DataCache.unlock();
        end
      end
    end
  end
  
end

