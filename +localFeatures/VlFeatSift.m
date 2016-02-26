classdef VlFeatSift < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.VlFeatSift VlFeat vl_sift wrapper
%   localFeatures.VlFeatSift('OptionName',OptionValue,...) Creates new
%   object which wraps around VLFeat covariant image frames detector.
%   All given options defined in the constructor are passed directly
%   to the vl_sift function when called.
%
%   The options to the constructor are the same as that for vl_sift
%   See help vl_sift to see those options and their default values.
%
%   See also: vl_sift

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    Opts
    VlSiftArguments
  end

  methods
    function obj = VlFeatSift(varargin)
      % def. arguments
      obj.Name = 'VLFeat SIFT';
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.VlSiftArguments = obj.checkInstall(varargin);
      obj.ExtractsDescriptors = true;
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = single(img); % If not already in uint8, then convert
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
        [frames] = vl_sift(img,obj.VlSiftArguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = vl_sift(img,obj.VlSiftArguments{:});
      end
      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      % extractDescriptor Extract SIFT descriptors of disc frames
      %   [DFRAMES DESCRIPTORS] = obj.extractDescriptor(IMG_PATH,
      %   FRAMES) Extracts SIFT descriptors DESCRIPTPORS of disc
      %   frames FRAMES from image defined by IMG_PATH. For the
      %   descriptor extraction, scale-space is used. Ellipses are
      %   converted to discs using their scale. The orientation of an
      %   oriented ellipse is dropped.
      import localFeatures.helpers.*;
      obj.info('Computing descriptors.');
      startTime = tic;
      % Get the input image
      img = imread(imagePath);
      imgSize = size(img);
      if numel(imgSize) == 3 && imgSize(3) > 1
        img = rgb2gray(img);
      end
      img = single(img);
      if size(frames,1) > 4
        % Convert frames to disks
        frames = [frames(1,:); frames(2,:); getFrameScale(frames)];
      end
      if size(frames,1) < 4
        % When no orientation, compute upright SIFT descriptors
        frames = [frames; zeros(1,size(frames,2))];
      end
      % Compute the descriptors (using scale space).
      [frames, descriptors] = vl_sift(img,'Frames',frames,...
        obj.VlSiftArguments{:});
      elapsedTime = toc(startTime);
      obj.debug('Descriptors computed in %gs',elapsedTime);
    end

    function sign = getSignature(obj)
      sign = [helpers.VlFeatInstaller.getBinSignature('vl_sift'),...
              helpers.cell2str(obj.VlSiftArguments)];
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.14')};
    end
  end
end
