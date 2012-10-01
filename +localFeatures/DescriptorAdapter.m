classdef DescriptorAdapter < localFeatures.GenericLocalFeatureExtractor
% DescriptorAdapter Join feature frame detector to a descriptor extractor
%   localFeatures.DescriptorAdapter(FRAME_DET, DESC_EXTRACT, ...) Constructs
%   an object of DESCRIPTORADAPTER which combines frame detection capabilities
%   of FRAME_DET object and descriptor extraction of DESC_EXTRACT object. Both
%   FRAME_DET and DESC_EXTRACT must be subclasses of
%   genericLocalFeatureExtractor. The name of the created loc. feat. extractor
%   is:
%
%     OBJ.Name = [FRAME_DET.Name ' + ' DESC_EXTRACT.Name]
%
%   This class is mainly an convenience wrapper which handles the
%   genericLocalFeatureExtractor methods and solves the issues of correct
%   caching of the results.

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess = protected)
    FrameDetector; % Handle to the frame detector
    DescExtractor; % Handle to the descriptor extractor
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
      if ~descExtractor.ExtractsDescriptors
        error('Class %s does not support descriptor extraction of provided frames',...
          descExtractor.Name);
      end
      obj.FrameDetector = frameDetector;
      obj.DescExtractor = descExtractor;
      obj.Name = [frameDetector.Name ' + ' descExtractor.Name];
      obj.configureLogger(obj.Name,varargin);

      obj.SupportedImgFormats = intersect(frameDetector.SupportedImgFormats,...
        descExtractor.SupportedImgFormats);
      % Handle the supported formats so double conversion is prevented
      if isempty(obj.SupportedImgFormats) || ischar(obj.SupportedImgFormats) ...
          || ismember('all',obj.SupportedImgFormats)
        % When there is no intersection or both are all, set to all so no
        % conversion is made in this class.
        obj.SupportedImgFormats = 'all';
      end
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      % Check also whether caching is not blocked in the det. or descr.
      if numel(frames) > 0 && obj.FrameDetector.UseCache ...
          && obj.DescExtractor.UseCache; return; end;
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
        frames = obj.FrameDetector.extractFeatures(imagePath);
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        % Prevent to convert image twice.
        [valImagePath imIsTmp] = obj.ensureImageFormat(imagePath);
        frames = obj.FrameDetector.extractFeatures(valImagePath);
        [frames descriptors] = ...
          obj.DescExtractor.extractDescriptors(valImagePath, frames);
        if imIsTmp, delete(valImagePath); end;
      end
      timeElapsed = toc(startTime);
      obj.debug('%d Features of image %s computed in %gs',...
        size(frames,2), getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      [frames descriptors] = ...
          obj.DescExtractor.extractDescriptors(imagePath, frames);
    end

    function sign = getSignature(obj)
      sign = [obj.FrameDetector.getSignature() '+'...
        obj.DescExtractor.getSignature()];
    end

    function disableCaching(obj)
      % DISABLECACHING Do not use cached features and always run the
      % features extractor.
      obj.UseCache = false;
      obj.FrameDetector.disableCaching();
      obj.DescExtractor.disableCaching();
    end

    function enableCaching(obj)
      % ENABLECACHING Do cache extracted features
      obj.UseCache = true;
      obj.FrameDetector.enableCaching();
      obj.DescExtractor.enableCaching();
    end
  end
end
