classdef ExampleLocalFeatureExtractor < localFeatures.GenericLocalFeatureExtractor
% EXAMPLELOCALFEATUREEXTRACTOR  An example wrapper for a local feature
%   To use your own feature extractor (detector and/or descriptor)
%   modify this class in the following manner.
%
%   1. Rename the class and the constructor.
%   2. Implement the constructor to set a default value for the
%      parameters of your feature.
%   3. Implement the EXTRACTFEATURE() method.

% Authors: Karel Lenc, Varun Gulshan, Andrea Vedaldi

% AUTORIGHTS

  properties (SetAccess=private, GetAccess=public)
    opts = struct(...
      'featuresDensity', 2e-3,... % Number of features  per pixel
      'frameType', 3,... % Disc
      'maxScale', 30,...
      'minScale', 1,...
      'descSize', 128,...
      'descMaxValue', 255,...
      'descMinValue', 0,...
      'descInteger', false... 
      );
  end

  methods
    function obj = ExampleLocalFeatureExtractor(varargin)
      % Implement a constructor to parse any option passed to the
      % feature extractor and store them in the obj.opts structure.

      % Name of the features extractor
      obj.name = 'Example Local Feature';
      % Name of the feature frames detector
      obj.detectorName = obj.name;
      % Name of descriptor extractor
      obj.descriptorName = obj.name;
      % Parse the options
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      % Configure the logger which is inherited
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;

      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;

      obj.info('generating frames for image %s.',getFileName(imagePath));

      img = imread(imagePath);
      imgSize = size(img);
      img = double(img) ;
      randn('state',mean(img(:))) ;
      rand('state',mean(img(:))) ;

      imageArea = imgSize(1) * imgSize(2);
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
      img = imread(imagePath);
      imgSize = size(img);

      imageArea = imgSize(1) * imgSize(2);
      numFeatures = round(imageArea * obj.opts.featuresDensity);
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
