classdef VlFeatMser < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.VlFeatMser class to wrap around the VLFeat MSER implementation
%   localFeatures.VlFeatMser('Option','OptionValue',...) constructs an object
%   of the wrapper around the detector.
%
%   The options to the constructor are the same as that for vl_mser
%   See help vl_mser to see those options and their default values.
%
%   See also: vl_mser

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % See help vl_mser for setting parameters for vl_mser
    vlMserArguments;
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = VlFeatMser(varargin)
      obj.Name = 'VLFeat MSER';
      varargin = obj.checkInstall(varargin);
      obj.vlMserArguments = obj.configureLogger(obj.Name,varargin);
    end

    function [frames] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));

      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img); % If not already in uint8, then convert

      [xx brightOnDarkFrames] = vl_mser(img,obj.vlMserArguments{:});
      [xx darkOnBrightFrames] = vl_mser(255-img,obj.vlMserArguments{:});

      frames = vl_ertr([brightOnDarkFrames darkOnBrightFrames]);
      sel = frames(3,:).*frames(5,:) - frames(4,:).^2 >= 1 ;
      frames = frames(:, sel) ;
      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      signList = {helpers.VlFeatInstaller.getBinSignature('vl_mser'),...
                  helpers.cell2str(obj.vlMserArguments)};
      sign = helpers.cell2str(signList);
    end
  end
  
  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.14')};
    end
  end
end
