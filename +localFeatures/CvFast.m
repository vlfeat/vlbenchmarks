classdef CvFast < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.CvFast feature extractor wrapper of OpenCV FAST detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as localFeatures.mex.cvFast.
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvFast helpers.OpenCVInstaller

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    CvFastArguments; % Arguments passed to cvFast function
    BinPath % Path to the mex binary
  end

  methods
    function obj = CvFast(varargin)
      obj.Name = 'OpenCV FAST';
      obj.DetectorName = obj.Name;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.CvFastArguments = obj.configureLogger(obj.Name,varargin);
      obj.BinPath = {which('localFeatures.mex.cvFast')};
    end

    function frames = extractFeatures(obj, imagePath)
      import helpers.*;

      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = uint8(img); % If not already in uint8, then convert
      [frames] = localFeatures.mex.cvFast(img,obj.CvFastArguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);      
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath{:}) ';'...
              helpers.cell2str(obj.CvFastArguments)];
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
      srclist = {fullfile(path,'cvFast.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
