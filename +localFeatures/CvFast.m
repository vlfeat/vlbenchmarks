classdef CvFast < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% CVFAST feature extractor wrapper of OpenCV FAST detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as localFeatures.mex.cvFast.
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvFast helpers.OpenCVInstaller

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    cvFast_arguments
    binPath
  end

  methods
    function obj = CvFast(varargin)
      obj.name = 'OpenCV FAST';
      obj.detectorName = obj.name;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.name,varargin);
      obj.cvFast_arguments = obj.configureLogger(obj.name,varargin);
      obj.binPath = {which('localFeatures.mex.cvFast')};
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
      [frames] = localFeatures.mex.cvFast(img,obj.cvFast_arguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);      
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.cvFast_arguments)];
    end
  end

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15') ...
        helpers.OpenCVInstaller()};
    end

    function [srclist flags] = getMexSources()
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvFast.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
