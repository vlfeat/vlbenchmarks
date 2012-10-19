classdef GenericLocalFeatureExtractor < handle & helpers.Logger
% GenericLocalFeatureExtractor Base class of a local feature extractors
%   GenericLocalFeatureExtractor defines the interface of a wrapper of
%   a local feature. This class inherits from HANDLE, so it is copied
%   by reference, not by value.
%
%   Derive this class to add your own feature extractor. See
%   ExampleLocalFeatureExtractor() for instructions.
%
%   Because some detector cannot split feature frame detection from the
%   descriptor extraction, there are three ways how to extract features
%   from an image using GenericLocalFeatureExtractor object LFE:
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
%   Constant property SupportedImageFormat is cell array of supported image
%   formats extension. If you extractor supports same formats as Matlab's
%   imread, keep it 'all'. This is used in descriptor adapter in order to
%   prevent double image conversion (for detector and for descriptor).
%
%   For creating a new feature extractor wrapper you can start from 
%   file TemplateWrapper.m.
%
%   See also: localFeatures.ExampleLocalFeatureExtractor
%     localFeatures.TemplateWrapper

% Authors: Karel Lenc, Varun Gulshan, Andrea Vedaldi

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    Name % General name of the feature extractor
  end

  properties (SetAccess=protected, GetAccess = public)
    UseCache = true; % Do cache results
    % If detector support desc. extraction of descriptors from provided
    % frames, set to true.
    ExtractsDescriptors = false;
    % Supported image formats, 'all' when supporting all formats as imread
    % or cell array of supported image formats.
    SupportedImgFormats = 'all';
  end

  properties (Constant, Hidden)
    FramesKeyPrefix = 'frames'; % Prefix of the cached features key
    DescsKeyPrefix = '+desc'; % Prefix of the cached features key
  end

  methods
    % The constructor of every class that inherits from this class is
    % expected to be used to set the options specific to that
    % detector.

    function [frames descriptors] = extractFeatures(obj, imagePath)
    % extractFeatures Extracts features frames and descriptors from image
    %   [FRAMES, DESCRIPTORS] = obj.extractFeatures(IMAGEPATH) is expected to
    %   extract fetures frames and optionally their descriptors from
    %   the image whose path is specified as input.
    %
    %   An implementation is also expected to cache the results by
    %   using the methods storeFeatures and loadFeatures.
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
    % extractDescriptors Extract descriptors for specified features  on an image
    %   [FRAMES, DESCRIPTORS] = obj.extractDescriptors(IMAGEPATH,
    %   FRAMES) is similar to EXTRACTFEATURES() but computes
    %   descriptors for the specified frames instead of running a
    %   detector.
      error('Not supported') ;
    end

    function sign = getSignature(obj)
    % getSignature Get a signature for a class instance
    %   The signature is a hash that should indentify a setting of
      error('Not supported') ;
    end
  end

  methods (Access = public)
    function disableCaching(obj)
      % disableCaching Do not use cached features and always run the
      % features extractor.
      obj.UseCache = false;
    end

    function enableCaching(obj)
      % enableCaching Do cache extracted features
      obj.UseCache = true;
    end
  end

  methods (Access = protected)
    function [frames descriptors] = loadFeatures(obj,imagePath,loadDescriptors)
      % [FRAMES DESCS] = obj.loadFeatures(IMG_PATH, LOAD_DESCS) Load features
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
      if ~obj.UseCache, return; end

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
      % storeFeatures Store extracted features to cache
      %   obj.storeFeatures(IMG_PATH, FRAMES) Store FRAMES detected in in 
      %   image IMG_PATH to a cache.
      %
      %   obj.storeFeatures(IMG_PATH, FRAMES, DESCRIPTORS) Store features 
      %   FRAMES and DESCRIPTORS extracted from an image IMG_PATH to a cache.
      % 
      %   Please note that calling with FRAMES or with FRAMES and DESCRIPTORS
      %   will create different records in the cache.
      %
      %   If obj.UseCache=false, nothing is done.
      if ~obj.UseCache, return; end
      hasDescriptors = true;
      if nargin < 4 || isempty(descriptors)
        descriptors = [];
        hasDescriptors = false;
      end

      key = obj.getFeaturesKey(imagePath, hasDescriptors);
      helpers.DataCache.storeData({frames,descriptors},key);
    end

    function key = getFeaturesKey(obj, imagePath, hasDescriptors)
      % KEY = obj.getFeaturesKey(IMG_PATH, HAS_DESCS) Get key KEY to features
      %   which are extracted from image IMG_PATH. When HAS_DESCS is true,
      %   returns key for a record in the cache which contains both frames
      %   and descriptors (or only frames when HAS_DESCS=false).
      import localFeatures.*;
      import helpers.*;
      imageSignature = helpers.fileSignature(imagePath);
      detSignature = obj.getSignature();
      prefix = GenericLocalFeatureExtractor.FramesKeyPrefix;
      if hasDescriptors
        prefix = strcat(prefix,GenericLocalFeatureExtractor.DescsKeyPrefix);
      end
      key = cell2str({prefix,detSignature,imageSignature});
    end
    
    function [imagePath isTemp] = ensureImageFormat(obj, imagePath)
    % ensureImageFormat Ensure that image format is supported
    % NIMAGE_PATH = obj.ensureImageFormat(IMG_PATH) checks
    %   whether image format, defined by its extension of IMG_PATH is
    %   supported, i.e. the extension is in SUPPORTED. If not, new
    %   temporary image '.ppm' or '.pgm' is created.
    %   This script suppose that at least the '.pgm' format is supported.
    % [NIMAGE_PATH IS_TMP] = obj.ensureImageFormat(IMG_PATH)
    %   IS_TMP is true when temporary image is created as this image
    %   should be deleted in the end.
      import helpers.*;
      isTemp = false;
      if ischar(obj.SupportedImgFormats) ...
          && strcmp(obj.SupportedImgFormats,'all')
        return;
      end
      [path name ext] = fileparts(imagePath);
      if ismember(ext, obj.SupportedImgFormats)
        return;
      else
        isTemp = true;
        % Create temporary image
        tmpPath = fileparts(tempname);
        tmpName = fullfile(tmpPath,[name ext]);
        image = imread(imagePath);
        if size(image,3) == 3
          if ismember('.ppm',obj.SupportedImgFormats)
            imagePath = [tmpName,'.ppm'];
            helpers.writenetpbm(image, imagePath);
          else
            imagePath = [tmpName,'.pgm'];
            image = rgb2gray(image);
            helpers.writenetpbm(image, imagePath);
          end
        elseif size(image,3) == 1
          imagePath = [tmpName,'.pgm'];
          helpers.writenetpbm(image, imagePath);
        end
      end
    end
  end
end
