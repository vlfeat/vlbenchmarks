classdef CvSurf < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% CVSURF feature extractor wrapper of OpenCV SURF detector
%
% Feature Extractor wrapper around the OpenCV SURF detector. This class
% constructor accepts the same options as localFeatures.mex.cvSurf.
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvSurf helpers.OpenCVInstaller

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    cvsurf_arguments
    binPath
  end

  methods
    function obj = CvSurf(varargin)
      obj.name = 'OpenCV SURF';
      obj.detectorName = obj.name;
      obj.descriptorName = obj.name;
      obj.extractsDescriptors = true;
      obj.cvsurf_arguments = obj.configureLogger(obj.name,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.install();
      end
      obj.binPath = {which('localFeatures.mex.cvSurf')};
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
        [frames] = localFeatures.mex.cvSurf(img,obj.cvsurf_arguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvSurf(img,obj.cvsurf_arguments{:});
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
      [frames descriptors] = mex.cvSurf(img,'Frames', ...
        frames,obj.cvsurf_arguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.cvsurf_arguments)];
    end
  end

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15')...
        helpers.OpenCVInstaller()};
    end

    function [srclist flags] = getMexSources()
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvSurf.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
