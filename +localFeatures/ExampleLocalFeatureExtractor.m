classdef ExampleLocalFeatureExtractor < localFeatures.GenericLocalFeatureExtractor
% EXAMPLELOCALFEATUREEXTRACTOR  An example wrapper for a local feature
%   To use your own feature extractor (detector and/or descriptor)
%   modify this class in the following manner.
%
%   1. Rename the class and the constructor.
%   2. Implement the constructor to set a default value for the
%      parameters of your feature.
%   3. Implement the EXTRACTFEATURES() method, eventually 
%      EXTRACTDESCRIPTORS method if your detector supports to detect
%      descriptors of given feature frames.
%
%   Frames are generated as a grid over the whole image with a selected
%   scales.
%
%   Descriptor of the frames is calculated as mean/variance/median of the
%   circular region defined by the frame scale.
%
%   This example detector need image processing toolbox.

% Authors: Karel Lenc, Varun Gulshan, Andrea Vedaldi

% AUTORIGHTS

  properties (SetAccess=private, GetAccess=public)
    % Set the default values of the detector options
    opts = struct(...
      'scales', 8:4:20,... % Generated scales
      'framesDistance',3,... % Distance between frames in grid (in scale)
      'useMean', true,... % Use mean value in a descriptor
      'useVariance', true,... % Use viarance in a descriptor
      'useMedian', true... % Use median in a descriptor
      );
  end

  methods
    function obj = ExampleLocalFeatureExtractor(varargin)
      % Implement a constructor to parse any option passed to the
      % feature extractor and store them in the obj.opts structure.

      % Information that this detector is able to extract descriptors
      obj.extractsDescriptors = true;
      % Name of the features extractor
      obj.name = 'Example detector';
      % Name of the feature frames detector
      obj.detectorName = 'Grid Frames';
      % Name of descriptor extractor
      obj.descriptorName = 'Example descriptor';
      % Parse the class options. See the properties of this class where the
      % options are defined.
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      % Configure the logger with the remaining constructor arguments which
      % were not 'consumed' by parameters of this detector.
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      % Because this class inherits from helpers.Logger, we can use its
      % methods for giving information to the user. Advantage of the logger
      % is that the user can set the class verbosity. See the
      % helpers.Logger documentation.
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end
      % If you want use cache, in the first step, try to load features from
      % the cache. The third argument of loadFeatures tells whether to load
      % descriptors as well.
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      % If features loaded, we are done
      if numel(frames) > 0; return; end;
      % Get the size of the image
      imgSize = helpers.imageSize(imagePath);
      % Generate the grid of frames in all user selected grids
      for scale = obj.opts.scales
        fDist = scale*obj.opts.framesDistance;
        xGrid = fDist:fDist:(imgSize(1) - fDist);
        yGrid = fDist:fDist:(imgSize(2) - fDist);
        [yCoords xCoords] = meshgrid(xGrid,yGrid);
        detFrames = [xCoords(:)';yCoords(:)';scale*ones(1,numel(xCoords))];
        frames = [frames detFrames];
      end
      % If the mehod is called with two output arguments, descriptors shall
      % be calculated
      if nargout > 1
        [frames descriptors] = obj.extractDescriptors(imagePath,frames);
      end
      timeElapsed = toc(startTime);
      obj.debug(sprintf('Features from image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
      % Store the generated frames and descriptors to the cache.
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      % EXTRACTDESCRIPTORS Compute mean, variance and median of the integer
      %   disk frame.
      %
      %   This is mean as an example how to work with the detected frames.
      %   The computed descriptor bears too few data to be distinctive.
      import localFeatures.helpers.*;
      obj.info('Computing descriptors.');
      startTime = tic;
      % Get the input image
      img = imread(imagePath);
      imgSize = size(img);
      if imgSize(3) > 1
        img = rgb2gray(img);
      end
      img = single(img);
      % Convert frames to integer disks
      frames = [round(frames(1,:)); ...
        round(frames(2,:)); ...
        round(getFrameScale(frames))];

      % Crop the frames which are out of image
      ellipses = frameToEllipse(frames);
      imgBBox = [1,1,imgSize([2 1])];
      isVisible = benchmarks.helpers.isEllipseInBBox(imgBBox, ellipses);
      frames = frames(:,isVisible);

      % Prealocate descriptors
      descriptors = zeros(3,size(frames,2));

      % Compute the descriptors as mean and variance of the image box
      % determined by the integer frame scale
      for fidx = 1:size(frames,2)
        x = round(frames(1,fidx));
        y = round(frames(2,fidx));
        s = floor(frames(3,fidx));
        frameBox = img(y-s:y+s,x-s:x+s);
        if obj.opts.useMean
          descriptors(1,fidx) = mean(frameBox(:));
        end
        if obj.opts.useVariance
          descriptors(2,fidx) = var(frameBox(:));
        end
        if obj.opts.useMedian
          descriptors(3,fidx) = median(frameBox(:));
        end
      end
      elapsedTime = toc(startTime);
      obj.debug('Descriptors computed in %gs',elapsedTime);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
  end
end % ----- end of class definition ----
