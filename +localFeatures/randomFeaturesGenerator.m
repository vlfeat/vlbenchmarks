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
      obj.name = 'Random features';
      obj.detectorName = obj.name;
      obj.descriptorName = obj.name;
      obj.extractsDescriptors = true;
      
      obj.opts.featuresDensity = 0.0005; % Number of features  per pixel
      
      obj.opts.frameType = obj.ORIENTED_DISC;
      obj.opts.maxScale = 30;
      obj.opts.minScale = 1;
      
      obj.opts.descSize = 128;
      obj.opts.descMaxValue = 255;
      obj.opts.descMinValue = 0;
      obj.opts.descInteger = false;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      obj.info('generating frames for image %s.',getFileName(imagePath));
      
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
      
      if nargout > 1
        [frames descriptors] = obj.extractDescriptors(imagePath,frames);
      end
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      descMinValue = obj.opts.descMinValue;
      descMaxValue = obj.opts.descMaxValue;
      descriptors = rand(obj.opts.descSize,numFeatures)...
        * (descMaxValue - descMinValue) + descMinValue;
      
      if obj.opts.descInteger
        descriptors = round(descriptors);
      end
    end
    
    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
    
  end

  methods (Static)

  end % ---- end of static methods ----

end % ----- end of class definition ----
