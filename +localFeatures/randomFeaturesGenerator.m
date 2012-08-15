% RANDOMFEATURESGENERATOR class to wrap around the CMP Hessian Affine detector
% implementatio

classdef randomFeaturesGenerator < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    opts
  end
 
  properties (Constant)
    DISC = 3;
    ORIENTED_DISC = 4;
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = randomFeaturesGenerator(varargin)
      import localFeatures.*;
      obj.detectorName = 'Random features';
      
      opts.featuresDensity = 0.0005; % Number of features  per pixel
      
      opts.frameType = obj.ORIENTED_DISC;
      opts.maxScale = 30;
      opts.minScale = 1;
      
      opts.descSize = 128;
      opts.descMaxValue = 128;
      opts.descMinValue = 0;
      opts.descInteger = false;
      obj.opts = vl_argparse(opts,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      Log.info(obj.detectorName,...
        sprintf('generating frames for image %s.',getFileName(imagePath)));
      
      img = imread(imagePath);
      imgSize = size(img);
      
      imageArea = prod(imgSize);
      numFeatures = round(imageArea * obj.opts.featuresDensity);
      
      locations = rand(2,numFeatures);
      locations(1,:) = locations(1,:) .* imgSize(2);
      locations(2,:) = locations(2,:) .* imgSize(1);
      scales = rand(1,numFeatures)*(obj.opts.maxScale - obj.opts.minScale) + obj.opts.minScale;
      
      switch obj.opts.frameType
        case obj.DISC
          frames = [locations;scales];
        case obj.ORIENTED_DISC
          angles = rand(1,numFeatures) * 2*pi;
          frames = [locations;scales;angles];
        otherwise
          error('Invalid frame type');
      end
      
      descMinValue = obj.opts.descMinValue;
      descMaxValue = obj.opts.descMaxValue;
      descriptors = rand(obj.opts.descSize,numFeatures)...
        * (descMaxValue - descMinValue) + descMinValue;
      
      if obj.opts.descInteger
        descriptors = round(descriptors);
      end
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
    
  end

  methods (Static)

  end % ---- end of static methods ----

end % ----- end of class definition ----
