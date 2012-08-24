% GENERICDETECTOR Abstract class that defines the interface for a
%   generic affine interest point detector.
%
%   It inherits from the handle class, so that means you can maintain state
%   inside an object of this class. If you have to add your own detector make
%   sure it inherits this class.
%   (see +localFeatures/exampleDetector.m for a simple example)

classdef genericLocalFeatureExtractor < handle & helpers.Logger
  
  properties (SetAccess=public, GetAccess=public)
    detectorName % Set this property in the constructor
  end
  
  properties (Constant)
    framesKeyPrefix = 'frames'; % Prefix of the cached features key
    descsKeyPrefix = '+desc'; % Prefix of the cached features key
  end

  methods(Abstract)
    % The constructor of every class that inherits from this class
    % is expected to be used to set the options specific to that
    % detector

    [frames descriptors] = extractFeatures(obj, imagePath)
    % EXTRACTFEATURES
    % Expect path to the source image on which the feature extraction
    % should be performed. For caching the results use methods
    % cacheFeatures and loadFeatures.
    %
    % The frames can be of the following format:
    % Output:
    %   frames: 3 x nFrames array storing the output regions as circles
    %     or
    %   frames: 5 x nFrames array storing the output regions as ellipses
    %
    %   frames(1,:) stores the X-coordinates of the points
    %   frames(2,:) stores the Y-coordinates of the points
    %
    %   if frames is 3 x nFrames, then frames(3,:) is the radius of the circles
    %   if frames is 5 x nFrames, then frames(3,:), frames(4,:) and frames(5,:)
    %   store respectively the S11, S12, S22 such that
    %   ELLIPSE = {x: x' inv(S) x = 1}.
    
    [frames descriptors] = extractDescriptors(obj, imagePath, frames)
    % EXTRACTDESCRIPTOR Extract descriptors of input frames
    % Extract descriptors of regions defined by frames in an image 
    % defined by its path imagePath. Outputs refined list of frames and
    % descriptors.
    
    sign = getSignature(obj)
    % GETSIGNATURE
    % Returns unique signature for detector parameters.
    %
    % This function is used for caching detected results. When the detector
    % parameters had changed, the signature must be different as well.
 
  end
  
  methods (Access = public)
    function clearCache(obj,imagePath)
      import helpers.*;
      
      key = obj.getFeaturesKey(imagePath,true);
      DataCache.removeData(key);
      key = obj.getFeaturesKey(imagePath,false);
      DataCache.removeData(key);
    end
  end

  methods (Access = protected)
    function [frames descriptors] = loadFeatures(obj,imagePath,loadDescriptors)
      import helpers.*;
      
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
        frames = [];
        descriptors = [];
      end
    end
    
    function storeFeatures(obj, imagePath, frames, descriptors)
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
