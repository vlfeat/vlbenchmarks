classdef VlFeatCovdet < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.VlFeatCovdet VLFeat vl_covdet wrapper
%   VlFeatCovdet('OptionName',OptionValue,...) creates new object
%   which wraps around VLFeat covariant image frames detector. All
%   given options defined in the constructor are passed directly to
%   the vl_covdet function when called.
%
%   The options to the constructor are the same as that for vl_covdet
%   See help vl_covdet to see those options and their default values.
%
%   See also: VL_COVDET().

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS

  properties (SetAccess=public, GetAccess=public)
    VlCovdetArguments
    Opts = struct('featureType','');
  end

  methods
    function obj = VlFeatCovdet(varargin)
      import helpers.*;
      obj.Name = 'VLFeat Covdet';
      varargin = obj.configureLogger(obj.Name,varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      obj.VlCovdetArguments = obj.checkInstall(varargin);
      obj.ExtractsDescriptors = true;
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      [frames, descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      img = imread(imagePath);
      if (size(img,3)>1), img = rgb2gray(img); end
      img = im2single(img) ;
      startTime = tic;
      if isempty(obj.Opts.featureType)
        if nargout == 1
          obj.info('Computing frames of image %s.',getFileName(imagePath));
          frames = vl_covdet(img, obj.VlCovdetArguments{:});
        else
          obj.info('Computing features of image %s.',...
                   getFileName(imagePath));
          [frames descriptors] = vl_covdet(img, obj.VlCovdetArguments{:});
        end
      else
        obj.info('Computing features of image %s.',getFileName(imagePath));
        [frames descriptors info] = vl_covdet(img, obj.VlCovdetArguments{:}) ;
        responses = info.peakScores;
        switch obj.Opts.featureType
          case 'min'
            valid = responses < 0;
          case 'max'
            valid = responses > 0;
        end
        frames = frames(:,valid);
        if nargout>1, descriptors = descriptors(:,valid); end;
      end
      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
                size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      image = imread(imagePath);
      if(size(image,3)>1), image = rgb2gray(image); end
      image = im2single(image); % If not already in uint8, then convert
      obj.info('Computing descriptors of %d frames.',size(frames,2));
      startTime = tic;
      [frames descriptors] = vl_covdet(image, ...
                                       'Frames', frames, ...
                                       obj.VlCovdetArguments{:},...
                                       'Verbose') ;
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.VlFeatInstaller.getBinSignature('vl_covdet'),...
              helpers.cell2str(obj.VlCovdetArguments) ...
              helpers.struct2str(obj.Opts)];
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.16')};
    end
  end
end
