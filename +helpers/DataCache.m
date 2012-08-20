classdef DataCache
  %DATACACHE Cache data into files
  %   Implementation of general data caching into files. Data are addressed
  %   by unique string 'key' and are stored in the file system.
  %
  %   The data are stored in path DataCache.dataPath and when the size of
  %   all sizes exceeds allowed size DataCache.dataPath the last recently
  %   used data are removed.
  %
  %   When DataCache.lockFiles = true the storage tries to be thread safe
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
  %     lockFiles - Lock files when are being read/written so they would
  %       not be overwritten/deleted. However the file is locked by writing
  %       empty file which does not get rid of all race conditions. Use
  %       carefully.
  %
  %   METHODS (Static)
  %     data = getData(key) - Get data from the cache indexed by string
  %       key. If the data has not been found, returns [];
  %     storeData(data,key) - Store data identified by key.
  %     removeData(key) - Remove data from the cache.
  %     clearCache() - Check the overall size of the cached data and delete
  %       last recently used data if exceedes.
  
  properties (Constant)
    maxDataSize = 2000*1024^2; % Max. size of data in cache in Bytes
    dataPath = fullfile(pwd,'data','cache',''); % Cached data storage
    dataFileVersion = '-V7'; % Version of the .mat files stored
    autoClear = true; % Clear data cache automatically
    lockFiles = false; % Prevent removal of accessed data, for SMP
  end
  
  methods (Static)
    
    function data = getData(key)
      % data = GETDATA(key) Get data from the cache indexed by string key.
      %   If the data has not been found, returns [];
      import helpers.DataCache;
      dataFile = DataCache.buildDataFileName(key);

      if exist(dataFile,'file')
        DataCache.lockFile(dataFile)
        packedData = load(dataFile,'packedData');
        packedData = packedData.packedData;
        if packedData.key == key
          DataCache.updateModificationDate(dataFile);
          DataCache.unlockFile(dataFile)
          data = packedData.data;
        else
          warning(strcat('Data collision for ',key));
          DataCache.unlockFile(dataFile)
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
      dataFile = DataCache.buildDataFileName(key);

      packedData.key = key;
      packedData.data = data;

      if DataCache.lockFiles
        while DataCache.isLocked(dataFile)
          pause(0.1)
        end
      end
      
      DataCache.lockFile(dataFile)
      save(dataFile,'packedData',DataCache.dataFileVersion);
      DataCache.unlockFile(dataFile)
      
      if DataCache.autoClear
        DataCache.clearCache();
      end
    end

    function removeData(key)
      % REMOVEDATA(KEY) - Remove data defined by KEY from the cache.
      import helpers.DataCache;
      dataFile = DataCache.buildDataFileName(key);
      if exist(dataFile,'file')
        if ~DataCache.isLocked(dataFile)
          delete(dataFile);
        else
          warning(strcat('Cannot delete locked data ',key));
        end
      else
        error(strcat('Cache data file for key ', key, ...
          'cannot be deleted (', dataFile, ').'));
      end
    end

    function clearCache()
      %CLEACACHE() - Check the overall size of the cached data and delete
      %   last recently used data if it exceedes the allowed size 
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
          % If file is locked it will be probably updated soon
          if ~DataCache.isLocked(fileName)
            delete(fullfile(DataCache.dataPath,fileName{:}));
          end
        end
      end
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
    
    function lockFile(fileName)
      import helpers.DataCache;
      if DataCache.lockFiles
        lockFileName = strcat(fileName,'.lock');
        lockFile = fopen(lockFileName,'w');
        fclose(lockFile);
      end
    end
    
    function unlockFile(fileName)
      import helpers.DataCache;
      if DataCache.lockFiles
        lockFileName = strcat(fileName,'.lock');
        if exist(lockFileName,'file')
          delete(lockFileName); 
        end
      end
    end
    
    function locked = isLocked(fileName)
      import helpers.DataCache;
      if DataCache.lockFiles
        lockFileName = strcat(fileName,'.lock');
        locked = exist(lockFileName,'file');
      else
        locked = false;
      end
    end
  end
  
end

