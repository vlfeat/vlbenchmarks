classdef GenericLocalFeatureExtractor < handle & helpers.Logger
% GENERICLOCALFEATUREEXTRACTOR Base class of a local feature extractors
%   GENERICLOCALFEATUREEXTRACTOR defines the interface of a wrapper of
%   a local feature. This class inherits from HANDLE, so it is copied
%   by reference, not by value.
%
%   Derive this class to add your own feature extractor. See
%   ExampleLocalFeatureExtractor() for instructions.
%
%   Because some detector cannot split feature frame detection from the
%   descriptor extraction, there are three ways how to extract features
%   from an image using GENERICLOCALFEATUREEXTRACTOR object LFE:
%
%   1. Detect feature frames
%     Feature frames only are extracted when calling method:
%
%       FRAMES = LFE.extractFeatures(IMAGE_PATH)
%
%   2. Detect feature frames and their descriptors
%     Feature frames and their descriptors are detected by calling method:
%
%       [FRAMES_WITH_DESCS DESCRIPTORS] = LFE.extractFeatures(IMAGE_PATH)
%
%     Where size(FRAMES_WITH_DESCS,2) == size(DESCRIPTORS,2). However
%     usually holds that size(FRAMES_WITH_DESCS,2) ~= size(FRAMES) (usually
%     because descriptors are calculated over bigger measurement region,
%     therefore some frames on the image border are cropped).
%
%   3. Detect descriptors of given frames:
%     Descriptors of given frames can be computed by calling method:
%
%       [FRAMES_WITH_DESCS DESCRIPTORS] = 
%             LFE.extractDescriptors(IMAGE_PATH, FRAMES)
%
%     When detector supports this method, usually it should hold that 
%     using frames from extractFeatures with one output variable in
%     extractDescriptors should give the same results as calling 
%     extractFeatures with two output arguments.
%
%   This class implements methods for storing detected features in a cache
%   which supports enabling/disabling caching using methods 
%   disableCaching() and enableCaching().
%
%   See also: extractFeatures, extractDescriptors

% Authors: Karel Lenc, Varun Gulshan, Andrea Vedaldi

% AUTORIGHTS

  properties (SetAccess=public, GetAccess=public)
    name % General name of the feature extractor
    detectorName = '' % Particular name of the frames detector
    descriptorName = '' % Name of descriptor extr. algorithm
  end

  properties (SetAccess=protected, GetAccess = public)
    useCache = true; % Do cache results
    % If detector support desc. extraction of descriptors from provided
    % frames, set to true.
    extractsDescriptors = false;
  end

  properties (Constant)
    framesKeyPrefix = 'frames'; % Prefix of the cached features key
    descsKeyPrefix = '+desc'; % Prefix of the cached features key
  end

  methods
    % The constructor of every class that inherits from this class is
    % expected to be used to set the options specific to that
    % detector.

    function [frames descriptors] = extractFeatures(obj, imagePath)
    % EXTRACTFEATURES Extracts features frames and descriptors from image
    %   [FRAMES, DESCRIPTORS] = EXTRACTFEATURES(IMAGEPATH) is expected to
    %   extract fetures frames and optionally their descriptors from
    %   the image whose path is specified as input.
    %
    %   An implementation is also expected to cache the results by
    %   using the methods CACHEFEATURES and LOADFEATURES.
    %
    %   FRAMES has a column for each feature frame (keypoint, region)
    %   detected. A column FRAME can have one of the followin formats:
    %
    %     * CIRCLES
    %       + FRAME(1:2)   center
    %       + FRAME(3)     radius
    %
    %     * ORIENTED CIRCLES
    %       + FRAME(1:2)   center
    %       + FRAME(3)     radius
    %       + FRAME(4)     orientation
    %
    %     * ELLIPSES
    %       + FRAME(1:2)   center
    %       + FRAME(3:5)   S11, S12, S22 such that ELLIPSE = {x: x' inv(S) x = 1}.
    %
    %     * ORIENTED ELLIPSES
    %       + FRAME(1:2)   center
    %       + FRAME(3:6)   stacking of A such that ELLIPSE = {A x : |x| = 1}
    %
    %
    %   When called only with one output argument, only frames are
    %   calculated. When invoked with two output arguments,
    %   descriptors of the frames are calculated. Note that the
    %   number of frames with descriptors may differ to number of frames
    %   which are extracted without descriptors.
    %
    %   See also: GenericLocalFeatureExtractor
      error('Not supported') ;
    end


    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
    % EXTRACTDESCRIPTOR Extract descriptors for specified features  on an image
    %   [FRAMES, DESCRIPTORS] = EXTRACTDESCRIPTORS(OBJ, IMAGEPATH,
    %   FRAMES) is similar to EXTRACTFEATURES() but computes
    %   descriptors for the specified frames instead of running a
    %   detector.
      error('Not supported') ;
    end

    function sign = getSignature(obj)
    % GETSIGNATURE Get a signature for a class instance
    %   The signature is a hash that should indentify a setting of
      error('Not supported') ;
    end
  end

  methods (Access = public)
    function disableCaching(obj)
      % DISABLECACHING Do not use cached features and always run the
      % features extractor.
      obj.useCache = false;
    end

    function enableCaching(obj)
      % ENABLECACHING Do cache extracted features
      obj.useCache = true;
    end
  end

  methods (Access = protected)
    function [frames descriptors] = loadFeatures(obj,imagePath,loadDescriptors)
      % [FRAMES DESCS] = LOADFEATURES(IMG_PATH, LOAD_DESCS) Load features
      %   extracted from image IMG_PATH from cache. If LOAD_DESCS is false,
      %   only FRAMES are loaded from cache. Please note that most of the
      %   descriptor extractors throw away several frames, therefore
      %   loading FRAMES or FRAMES and DESCRIPTORS may return different set
      %   of frames.
      %   If no cache entry has been found or useCache=false, empty array
      %   is returned.
      import helpers.*;
      frames = [];
      descriptors = [];
      if ~obj.useCache, return; end

      key = obj.getFeaturesKey(imagePath,loadDescriptors);
      data = DataCache.getData(key);
      if ~isempty(data)
        [frames, descriptors] = data{:};
        if loadDescriptors
          obj.debug('Frames and descriptors loaded from cache');
        else
          obj.debug('Frames loaded from cache');
        end
      else
        return
      end
    end

    function storeFeatures(obj, imagePath, frames, descriptors)
      % STOREFEATURES(IMG_PATH, FRAMES) Store FRAMES detected in in image 
      %   IMG_PATH to a cache.
      % STOREFEATURES(IMG_PATH, FRAMES, DESCRIPTORS) Store features FRAMES
      %   and DESCRIPTORS extracted from an image IMG_PATH to a cache.
      % 
      % Please note that calling with FRAMES or with FRAMES and DESCRIPTORS
      % will create different records in the cache.
      %
      % If useCache=false, nothing is done.
      if ~obj.useCache, return; end
      hasDescriptors = true;
      if nargin < 4 || isempty(descriptors)
        descriptors = [];
        hasDescriptors = false;
      end

      key = obj.getFeaturesKey(imagePath, hasDescriptors);
      helpers.DataCache.storeData({frames,descriptors},key);
    end

    function key = getFeaturesKey(obj, imagePath, hasDescriptors)
      % KEY = GETFEATURESKEY(IMG_PATH, HAS_DESCS) Get key KEY to features
      %   which are extracted from image IMG_PATH. When HAS_DESCS is true,
      %   returns key for a record in the cache which contains both frames
      %   and descriptors (or only frames when HAS_DESCS=false).
      import localFeatures.*;
      import helpers.*;
      imageSignature = helpers.fileSignature(imagePath);
      detSignature = obj.getSignature();
      prefix = GenericLocalFeatureExtractor.framesKeyPrefix;
      if hasDescriptors
        prefix = strcat(prefix,GenericLocalFeatureExtractor.descsKeyPrefix);
      end
      key = cell2str({prefix,detSignature,imageSignature});
    end

  end % ------- end of methods --------

end % -------- end of class ---------
