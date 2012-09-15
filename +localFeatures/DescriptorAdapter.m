classdef DescriptorAdapter < localFeatures.GenericLocalFeatureExtractor
% DESCRIPTORADAPTER Join feature frame detector to a descriptor extractor
%   DESCRIPTORADAPTER(FRAME_DET, DESC_EXTRACT, ...) Constructs an object
%   of DESCRIPTORADAPTER which combines frame detection capabilities of
%   FRAME_DET object and descriptor extraction of DESC_EXTRACT object.
%   Both FRAME_DET and DESC_EXTRACT must be subclasses of
%   genericLocalFeatureExtractor.
%   The name of the created loc. feat. extractor is:
%
%     OBJ.name = [FRAME_DET.detectorName '+' DESC_EXTRACT.descriptorName]
%
%   This class is mainly an convinience wrapper which handles the
%   genericLocalFeatureExtractor methods and solves the issues of correct
%   caching of the results.

% AUTORIGHTS
  properties (SetAccess = protected)
    frameDetector;
    descExtractor;
  end

  methods
    function obj = DescriptorAdapter(frameDetector, descExtractor, varargin)
      if ~ismember('localFeatures.GenericLocalFeatureExtractor',...
          superclasses(frameDetector))
        error('FrameDetector not a GenericLocalFeatureExtractor.');
      end
      if ~ismember('localFeatures.GenericLocalFeatureExtractor',...
          superclasses(descExtractor))
        error('FrameDetector not a GenericLocalFeatureExtractor.');
      end
      if ~descExtractor.extractsDescriptors
        error('Class %s does not support descriptor extraction of provided frames',...
          descExtractor.name);
      end
      obj.frameDetector = frameDetector;
      obj.descExtractor = descExtractor;
      obj.detectorName = frameDetector.detectorName;
      obj.descriptorName = descExtractor.descriptorName;
      obj.name = [obj.detectorName ' + ' obj.descriptorName];
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      % Check also whether caching is not blocked in the det. or descr.
      if numel(frames) > 0 && obj.frameDetector.useCache ...
          && obj.descExtractor.useCache; return; end;
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
        frames = obj.frameDetector.extractFeatures(imagePath);
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        frames = obj.frameDetector.extractFeatures(imagePath);
        [frames descriptors] = ...
          obj.descExtractor.extractDescriptors(imagePath, frames);
      end
      timeElapsed = toc(startTime);
      obj.debug('Features of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      [frames descriptors] = ...
          obj.descExtractor.extractDescriptors(imagePath, frames);
    end

    function sign = getSignature(obj)
      sign = [obj.frameDetector.getSignature() '+'...
        obj.descExtractor.getSignature()];
    end

    function disableCaching(obj)
      % DISABLECACHING Do not use cached features and always run the
      % features extractor.
      obj.useCache = false;
      obj.frameDetector.disableCaching();
      obj.descExtractor.disableCaching();
    end

    function enableCaching(obj)
      % ENABLECACHING Do cache extracted features
      obj.useCache = true;
      obj.frameDetector.enableCaching();
      obj.descExtractor.enableCaching();
    end
  end % ------- end of methods --------
end % -------- end of class ---------
