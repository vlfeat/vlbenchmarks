classdef CvSurf < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.CvSurf feature extractor wrapper of OpenCV SURF detector
%
% Feature Extractor wrapper around the OpenCV SURF detector. This class
% constructor accepts the same options as localFeatures.mex.cvSurf.
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvSurf helpers.OpenCVInstaller

% Atuhors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    CvsurfArguments; % Arguments passed to cvSurf function
    BinPath; % Path to the mex binary
  end

  methods
    function obj = CvSurf(varargin)
      obj.Name = 'OpenCV SURF';
      obj.ExtractsDescriptors = true;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.CvsurfArguments = obj.configureLogger(obj.Name,varargin);
      obj.BinPath = {which('localFeatures.mex.cvSurf')};
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
        [frames] = localFeatures.mex.cvSurf(img,obj.CvsurfArguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvSurf(img,obj.CvsurfArguments{:});
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
      [frames descriptors] = mex.cvSurf(img,'Frames', ...
        frames,obj.CvsurfArguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath{:}) ';'...
              helpers.cell2str(obj.CvsurfArguments)];
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15')...
        helpers.OpenCVInstaller()};
    end

    function [srclist flags] = getMexSources(obj)
      import helpers.*;
      path = fullfile(pwd,'+localFeatures','+mex','');
      srclist = {fullfile(path,'cvSurf.cpp')};
      flags = {[OpenCVInstaller.getMexFlags() ' ' VlFeatInstaller.getMexFlags() ]};
    end
  end
end
