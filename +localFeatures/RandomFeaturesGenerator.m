classdef RandomFeaturesGenerator < localFeatures.GenericLocalFeatureExtractor
% localFeatures.RandomFeaturesGenerator Random features generator
%   localFeatures.RandomFeaturesGenerator('OptionName','OptionValue',...)
%   Constructs and object of random features generator. This class generated
%   bot frames and descriptors based on the given options. Frames locations
%   are generated with uniform distribution over the input image with density
%   defined by 'FeaturesDensity' parameter. The supported frames types are
%   Discs and Oriented Discs. Scale of the generated frames is generated with
%   uniform distribution limited by 'MaxScale' and 'MinScale' parameter. Frame
%   orientations are uniformly distributed in interval [0, 2*pi].
%
%   Descriptors generation can be affected by parameters 'DescMinValue' and
%   'DescMaxValue' and 'DescInteger' for integer descriptors generation.
%
%   In constructor you can define the following parameters:
%
%   FeaturesDensity:: 2e-1
%     Number of features per image pixel.
%
%   FrameType:: RandomFeaturesGenerator.DISC
%     Type of the generated frames. Supported are:
%     RandomFeaturesGenerator.DISC and RandomFeaturesGenerator.ORIENTED_DISC
%
%   MaxScale:: 30
%     Maximum scale of generated frames.
%
%   MinScale:: 1
%     Minimum scale of generated frames.
%
%   DescSize:: 128
%     Number of elements in generated descriptors.
%
%   DescMaxValues:: 255
%     Maximal value in a descriptor vector.
%
%   DescMinValue:: 0
%     Minimal value in a descriptor vector.
%
%   DescInteger:: false
%     Generate descriptors as integers.

% Authors: Karel Lenc, Andrea Vedaldi

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'featuresDensity', 2e-3,... % Number of features  per pixel
      'frameType', localFeatures.RandomFeaturesGenerator.DISC,...
      'maxScale', 30,...
      'minScale', 1,...
      'descSize', 128,...
      'descMaxValue', 255,...
      'descMinValue', 0,...
      'descInteger', false... 
      );
  end

  properties (Constant)
    DISC = 3;
    ORIENTED_DISC = 4;
  end

  methods
    function obj = RandomFeaturesGenerator(varargin)
      import localFeatures.*;
      import helpers.*;
      obj.Name = 'Random features';
      obj.ExtractsDescriptors = true;
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.Opts = vl_argparse(obj.Opts,varargin);
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
      numFeatures = round(imageArea * obj.Opts.featuresDensity);

      locations = rand(2,numFeatures);
      locations(1,:) = locations(1,:) .* imgSize(2);
      locations(2,:) = locations(2,:) .* imgSize(1);
      scales = rand(1,numFeatures)*(obj.Opts.maxScale - obj.Opts.minScale) + obj.Opts.minScale;

      switch obj.Opts.frameType
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
      numFeatures = round(imageArea * obj.Opts.featuresDensity);
      descMinValue = obj.Opts.descMinValue;
      descMaxValue = obj.Opts.descMaxValue;
      descriptors = rand(obj.Opts.descSize,numFeatures)...
        * (descMaxValue - descMinValue) + descMinValue;

      if obj.Opts.descInteger
        descriptors = round(descriptors);
      end
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end
  end
end
