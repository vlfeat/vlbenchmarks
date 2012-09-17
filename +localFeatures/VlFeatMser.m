classdef VlFeatMser < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% VLFEATMSER class to wrap around the VLFeat MSER implementation
%   VLFEATMSER('Option','OptionValue',...) constructs an object of the
%   wrapper around the detector.
%
%   The options to the constructor are the same as that for vl_mser
%   See help vl_mser to see those options and their default values.
%
%   See also: vl_mser

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % See help vl_mser for setting parameters for vl_mser
    vl_mser_arguments
    binPath
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = VlFeatMser(varargin)
      obj.name = 'VLFeat MSER';
      obj.detectorName = obj.name;
      varargin = obj.checkInstall(varargin);
      obj.vl_mser_arguments = obj.configureLogger(obj.name,varargin);
      obj.binPath = which('vl_mser');
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

      [xx brightOnDarkFrames] = vl_mser(img,obj.vl_mser_arguments{:});
      [xx darkOnBrightFrames] = vl_mser(255-img,obj.vl_mser_arguments{:});

      frames = vl_ertr([brightOnDarkFrames darkOnBrightFrames]);
      sel = frames(3,:).*frames(5,:) - frames(4,:).^2 >= 1 ;
      frames = frames(:, sel) ;
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.binPath), ...
                  helpers.cell2str(obj.vl_mser_arguments)};
      sign = helpers.cell2str(signList);
    end
  end
  
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.VlFeatInstaller('0.9.14')};
    end
  end
end
