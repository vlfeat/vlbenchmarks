classdef VlFeatCovdet < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% VLFEATCOVDET class to wrap around the VLFeat Frame det implementation
%   VLFEATCOVDET('OptionName',OptionValue,...) Created new object which
%   wraps around VLFeat covariant image frames detector. All given options
%   defined in the constructor are passed directly to the vl_covdet 
%   function when called.
%
%   The options to the constructor are the same as that for vl_covdet
%   See help vl_covdet to see those options and their default values.
%
%   See also: vl_covdet

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    opts
    vl_covdet_arguments
    binPath
  end

  methods
    function obj = VlFeatCovdet(varargin)
      % def. arguments
      vlArgs.method = 'DoG';
      vlArgs.affineAdaptation = false;
      [vlArgs, drop] = vl_argparse(vlArgs,varargin);
      obj.name = ['VLFeat ' vlArgs.method];
      if vlArgs.affineAdaptation, obj.name = [obj.name '-affine']; end
      obj.detectorName = obj.name;
      obj.descriptorName = 'VLFeat SIFT';
      obj.extractsDescriptors = true;
      obj.opts.forceOrientation = false; % Force orientation for SIFT desc.
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      varargin = obj.checkInstall(varargin);
      % Rest of the arguments use as vl_covdet arguments
      obj.vl_covdet_arguments = obj.configureLogger(obj.name,varargin);
      obj.binPath = {which('vl_covdet') which('libvl.so')};
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
        [frames] = vl_covdet(img,obj.vl_covdet_arguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = vl_covdet(img,obj.vl_covdet_arguments{:});
      end
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      numValues = size(frames,1);
      if numValues < 3 || numValues > 6
        error('Invalid frames format');
      end
      hasAffineShape = numValues > 4;
      hasOrientation = numValues == 4 || numValues == 6;
      if nargin >= 3
        if obj.opts.forceOrientation
          hasOrientation = true; % force calculating orientations
        end
      end
      image = imread(imagePath);
      if(size(image,3)>1), image = rgb2gray(image); end
      image = single(image); % If not already in uint8, then convert
      obj.info('Computing descriptors of %d frames.',size(frames,2));
      startTime = tic;
      [frames descriptors] = vl_covdet(image, 'Frames', frames,...
          'AffineAdaptation',hasAffineShape,'Orientation', hasOrientation);
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.vl_covdet_arguments)];
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.15')};
    end
  end
end
