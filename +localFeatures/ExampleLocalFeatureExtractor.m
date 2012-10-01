classdef ExampleLocalFeatureExtractor < helpers.GenericInstaller ...
    & localFeatures.GenericLocalFeatureExtractor
% localFeatures.ExampleLocalFeatureExtractor Example image feature extractor
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

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % Set the default values of the detector options
    Opts = struct(...
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
      % feature extractor and store them in the obj.Opts structure.

      % Information that this detector is able to extract descriptors
      obj.ExtractsDescriptors = true;
      % Name of the features extractor
      obj.Name = 'Example detector';
      % Because this class inherits methods from helpers.GenericInstalles
      % we can test whether this detector is installed
      varargin = obj.checkInstall(varargin);
      % Configure the logger. The parameters accepted by logger are
      % consumend and the rest is passed back to varargin.
      varargin = obj.configureLogger(obj.Name,varargin);
      % Parse the class options. See the properties of this class where the
      % options are defined.
      obj.Opts = vl_argparse(obj.Opts,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;

      startTime = tic;
      % Because this class inherits from helpers.Logger, we can use its
      % methods for giving information to the user. Advantage of the 
      % logger is that the user can set the class verbosity. See the
      % helpers.Logger documentation.
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
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
      for scale = obj.Opts.scales
        fDist = scale*obj.Opts.framesDistance;
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
        if obj.Opts.useMean
          descriptors(1,fidx) = mean(frameBox(:));
        end
        if obj.Opts.useVariance
          descriptors(2,fidx) = var(frameBox(:));
        end
        if obj.Opts.useMedian
          descriptors(3,fidx) = median(frameBox(:));
        end
      end
      elapsedTime = toc(startTime);
      obj.debug('Descriptors computed in %gs',elapsedTime);
      % This method does not cache the computed values as it is complicated
      % to compute a signature of the input frames.
    end

    function signature = getSignature(obj)
      % This method is called from loadFeatures and  storeFeatures methods
      % to ge uniqie string for the detector properties. Because this is
      % influenced both by the detector settings and its implementation,
      % the string signature of both of them.
      % fileSignature returns a string which contain information about the
      % file including the last modification date.
      signature = [helpers.struct2str(obj.Opts),';',...
        helpers.fileSignature(mfilename('fullpath'))];
    end
  end

  methods(Static)
    %  Because this class is is subclass of GenericInstaller it can benefit
    %  from its support. When GenericInstaller.install() method is called,
    %  the following operations are performed when it was detected that the
    %  class is not installed:
    %
    %    1. Install dependencies
    %    2. Download and unpack tarballs
    %    3. Run compilation
    %    4. Compile mex files
    %    5. Setup the class
    %
    %  These steps are defined by the following static methods
    %  implementations:
    %
    %   deps = getDependencies()
    %     Define the dependencies, i.e. instances of GenericInstaller which
    %     are installed when method install() is called.
    %
    %   [urls dstPaths] = getTarballsList()
    %     Returns urls = {archive_1_url, archive_2_url,...} and 
    %     dstPaths = {archive_1_dst_path,...} and defines which files
    %     should be downloaded when install() is called.
    %
    %   compile()
    %     User defined method which is called after installing all tarballs
    %     and when isCompiled returns false.
    %
    %   res = isCompiled()
    %     User defined method to test whether compile() method should be
    %     called to complete the class isntallation.
    %
    %   [srclist flags]  = getMexSources()
    %     Returns srclist = {path_to_mex_files} and their flags which are
    %     compiled using mex command. See helpers.Installer for an example.
    %
  end
end
