% DESCRIPTORADAPTER

classdef descriptorAdapter < localFeatures.genericLocalFeatureExtractor

  properties (SetAccess = protected)
    frameDetector;
    descExtractor;
  end
  
  methods
    function obj = descriptorAdapter(frameDetector, descExtractor, varargin)
      
      if ~ismember('localFeatures.genericLocalFeatureExtractor',...
          superclasses(frameDetector))
        error('FrameDetector not a genericLocalFeatureExtractor.');
      end
      if ~ismember('localFeatures.genericLocalFeatureExtractor',...
          superclasses(descExtractor))
        error('FrameDetector not a genericLocalFeatureExtractor.');
      end
      
      if ~descExtractor.extractsDescriptors
        error('Class % does not support descriptor extraction of provided frames',...
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
      if numel(frames) > 0; return; end;
      
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
