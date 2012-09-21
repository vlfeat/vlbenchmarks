classdef CvOrb < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.CvOrb feature extractor wrapper of OpenCV ORB detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as localFeatures.mex.cvOrb.
%
% Matching the produced BRIEF descritpors, special hamming distance has to
% be used (because of their binary nature). Descriptors are exported as
% uint8 array.
%
% This detector depends on OpenCV library.
%
% See also: localFeatures.mex.cvOrb helpers.OpenCVInstaller

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    CvOrbArguments; % Arguments passed to cvOrb mex
    Opts; % Object options
    BinPath; % Mex file path
  end

  methods
    function obj = CvOrb(varargin)
      import helpers.*;
      obj.Opts.scoreType = 'FAST';
      [obj.Opts, drop] = vl_argparse(obj.Opts, varargin);
      obj.Name = 'OpenCV ORB';
      obj.DetectorName = [obj.Name,' ',obj.Opts.scoreType];
      obj.DescriptorName = obj.Name;
      obj.ExtractsDescriptors = true;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.CvOrbArguments = varargin;
      obj.BinPath = {which('localFeatures.mex.cvOrb')};
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
        [frames] = localFeatures.mex.cvOrb(img,obj.CvOrbArguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvOrb(img,obj.CvOrbArguments{:});
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
      [frames descriptors] = mex.cvOrb(img,'Frames',...
        frames,obj.CvOrbArguments{:});
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath{:}) ';'...
              helpers.cell2str(obj.CvOrbArguments)];
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
      srclist = {fullfile(path,'cvOrb.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
