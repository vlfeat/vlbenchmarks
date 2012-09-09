classdef genericLocalFeatureExtractor < handle & helpers.Logger
% GENERICLOCALFEATUREEXTRACTOR Base class of a local feature extractor wrapper
%   GENERICLOCALFEATUREEXTRACTOR defines the interface of a wrapper of
%   a local feature. This class inherits from HANDLE, so it is copied
%   by reference, not by value.
%
%   Derive this class to add your own feature extractor. See
%   EXAMPLELOCALFEATUREEXTRACTOR() for instructions.

% Authors: Karel Lenc, Varun Gulshan, Andrea Vedaldi

% AUTORIGHTS

  properties (SetAccess=public, GetAccess=public)
    name % General name of the feature extractor
    detectorName = '' % Particular name of the frames detector
    descriptorName = '' % Name of descriptor extr. algorithm
    % If detector support desc. extraction of descriptors from provided
    % frames, set to true.
    extractsDescriptors = false;
  end

  properties (SetAccess=protected, GetAccess = public)
    useCache = true; % Do cache results
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
    %   frames computed in the two cases may differ as in certain
    %   cases the descriptors cannot be computed for some frames
    %   (e.g. if too close to the image boundary).
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
      import localFeatures.*;
      import helpers.*;
      imageSignature = helpers.fileSignature(imagePath);
      detSignature = obj.getSignature();
      prefix = genericLocalFeatureExtractor.framesKeyPrefix;
      if hasDescriptors
        prefix = strcat(prefix,genericLocalFeatureExtractor.descsKeyPrefix);
      end
      key = cell2str({prefix,detSignature,imageSignature});
    end

  end % ------- end of methods --------

end % -------- end of class ---------
