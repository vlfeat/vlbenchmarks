% CVSIFT feature extractor wrapper of OpenCV SIFT detector
%
% Feature Extractor wrapper around the OpenCV SIFT detector. This class
% constructor accepts the same options as <a href="matlab: help localFeatures.mex.cvSift">localFeatures.mex.cvSift</a>
%


classdef cvSift < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=public, GetAccess=public)
    cvsift_arguments
    binPath
  end

  methods

    function obj = cvSift(varargin)
      obj.detectorName = 'OpenCV SIFT';
      obj.cvsift_arguments = obj.configureLogger(obj.detectorName,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.installDeps();
      end
      
      obj.binPath = {which('localFeatures.mex.cvSift')};
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = uint8(img);
      
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
        [frames] = localFeatures.mex.cvSift(img,obj.cvsift_arguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvSift(img,obj.cvsift_arguments{:});
      end
      timeElapsed = toc(startTime);
      
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      import localFeatures.*;
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = uint8(img);
      
      startTime = tic;
      [frames descriptors] = mex.cvSift(img,'Frames', ...
        frames,obj.cvorb_arguments{:});
      timeElapsed = toc(startTime);
      
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.cvsift_arguments)];
    end
  end
  
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.VlFeatInstaller() ...
        helpers.OpenCVInstaller()};
    end
    
    function [srclist flags] = getMexSources()
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvSift.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
