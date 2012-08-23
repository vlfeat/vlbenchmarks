% cvStar feature extractor wrapper of OpenCV FAST detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as <a href="matlab: help localFeatures.mex.cvStar">localFeatures.mex.cvStar</a>
%


classdef cvStar < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=public, GetAccess=public)
    cvStar_arguments
    binPath
  end

  methods

    function obj = cvStar(varargin)
      obj.detectorName = 'OpenCV STAR';
      obj.cvStar_arguments = obj.configureLogger(obj.detectorName,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.installDeps();
      end
      
      obj.binPath = {which('localFeatures.mex.cvStar')};
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
      
      [frames] = localFeatures.mex.cvStar(img,obj.cvStar_arguments{:});
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, []);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.cvStar_arguments)];
    end
  end
  
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.VlFeatInstaller() helpers.OpenCVInstaller()};
    end
    
    function [srclist flags] = getMexSources()
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvStar.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
