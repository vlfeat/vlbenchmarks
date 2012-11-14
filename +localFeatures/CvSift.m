classdef CvSift < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.CvSift feature extractor wrapper of OpenCV SIFT detector
%
% Feature Extractor wrapper around the OpenCV SIFT detector. This class
% constructor accepts the same options as localFeatures.mex.cvSift
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvSift helpers.OpenCVInstaller

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    CvSiftArguments; % Arguments passed to cvSift mex
    BinPath; % MAth of the mex binary
  end

  methods
    function obj = CvSift(varargin)
      obj.Name = 'OpenCV SIFT';
      obj.ExtractsDescriptors = true;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.CvSiftArguments = obj.configureLogger(obj.Name,varargin);
      obj.BinPath = {which('localFeatures.mex.cvSift')};
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
        [frames] = localFeatures.mex.cvSift(img,obj.CvSiftArguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvSift(img,obj.CvSiftArguments{:});
      end
      timeElapsed = toc(startTime);
      obj.debug('%d Frames of image %s computed in %gs',...
        size(frames,2), getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      import localFeatures.*;
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = uint8(img);
      startTime = tic;
      frames = [frames(1:2,:); localFeatures.helpers.getFrameScale(frames)];
      [frames descriptors] = mex.cvSift(img,'Frames', ...
        frames,obj.CvSiftArguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath{:}) ';'...
              helpers.cell2str(obj.CvSiftArguments)];
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
      srclist = {fullfile(path,'cvSift.cpp')};
      flags = {[OpenCVInstaller.getMexFlags() ' ' VlFeatInstaller.getMexFlags() ]};
    end
  end
end
