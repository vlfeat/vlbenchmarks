classdef VlFeatSift < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% VLFEATSIFT class to wrap around the VLFeat Frame det implementation
%   VLFEATSIFT('OptionName',OptionValue,...) Created new object which
%   wraps around VLFeat covariant image frames detector. All given options
%   defined in the constructor are passed directly to the vl_sift 
%   function when called.
%
%   The options to the constructor are the same as that for vl_sift
%   See help vl_sift to see those options and their default values.
%
%   See also: vl_sift

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    opts
    vl_sift_arguments
    binPath
  end

  methods
    function obj = VlFeatSift(varargin)
      % def. arguments
      obj.name = 'VLFeat SIFT';
      obj.detectorName = 'VLFeat DoG';
      obj.descriptorName = 'VLFeat SIFT';
      obj.vl_sift_arguments = obj.configureLogger(obj.name,varargin);
      obj.binPath = {which('vl_sift') which('libvl.so')};
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
        [frames] = vl_sift(img,obj.vl_sift_arguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = vl_sift(img,obj.vl_sift_arguments{:});
      end
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.vl_sift_arguments)];
    end
  end

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.VlFeatInstaller('0.9.14')};
    end
  end
end
