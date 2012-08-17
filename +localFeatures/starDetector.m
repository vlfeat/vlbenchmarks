% STARDETECTOR

classdef starDetector < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=public, GetAccess=public)
    opts
  end
  
  properties (SetAccess=private, GetAccess=public)
    binPath
  end

  methods
    function obj = starDetector(varargin)
      detectorName = 'Star Detector';
      obj = obj@localFeatures.genericLocalFeatureExtractor(detectorName,varargin);
      cwd=fileparts(mfilename('fullpath'));
      path = fullfile(cwd,'thirdParty/censure/');
      obj.binPath = fullfile(path,'star_detector');
      
      obj.opts.n = 7;
      obj.opts.response_threshold = 30;
      obj.opts.line_threshold_projected = 10;
      obj.opts.line_threshold_binarized = 8;
      obj.opts.verbose = 0;
      
      [obj.opts varargin] = vl_argparse(obj.opts,obj.remArgs);
      obj.configureLogger(obj.detectorName,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      obj.info('computing frames for image %s.',getFileName(imagePath)); 

      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img);

      [frames] = star_detector(img,obj.opts);
      
      frames = [[frames.x]; [frames.y]; [frames.s]];
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';'...
              helpers.struct2str(obj.opts)];
    end

  end

end
