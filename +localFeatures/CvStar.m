classdef CvStar < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.CvStar feature extractor wrapper of OpenCV FAST detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as localFeatures.mex.cvStar
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvStar helpers.OpenCVInstaller

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    CvStarArguments; % Arguments passed to cvStar function
    BinPath; % Path to the mex binary
  end

  methods
    function obj = CvStar(varargin)
      obj.Name = 'OpenCV STAR';
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.CvStarArguments = obj.configureLogger(obj.Name,varargin);
      obj.BinPath = {which('localFeatures.mex.cvStar')};
    end

    function frames = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;

      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = uint8(img); % If not already in uint8, then convert
      [frames] = localFeatures.mex.cvStar(img,obj.CvStarArguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath{:}) ';'...
              helpers.cell2str(obj.CvStarArguments)];
    end
  end
  
  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15') ...
        helpers.OpenCVInstaller()};
    end

    function [srclist flags] = getMexSources(obj)
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvStar.cpp')};
      flags = {[OpenCVInstaller.getMexFlags() ' ' VlFeatInstaller.getMexFlags() ]};
    end
  end
end
