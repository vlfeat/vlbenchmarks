% cvOrb feature extractor wrapper of OpenCV ORB detector
%
% Feature Extractor wrapper around the OpenCV ORB detector. This class
% constructor accepts the same options as <a href="matlab: help localFeatures.mex.cvOrb">localFeatures.mex.cvOrb</a>
%
% Matching the produced BRIEF descritpors, special hamming distance has to
% be used (because of their binary nature). Descriptors are exported as
% uint8 array.
%


classdef cvOrb < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=public, GetAccess=public)
    cvorb_arguments
    opts
    binPath
  end

  methods

    function obj = cvOrb(varargin)
      obj.opts.scoreType = 'FAST';
      [obj.opts, drop] = vl_argparse(obj.opts, varargin);
      obj.name = 'OpenCV ORB';
      obj.detectorName = [obj.name,' ',obj.opts.scoreType];
      obj.descriptorName = obj.name;
      obj.extractsDescriptors = true;
      
      obj.cvorb_arguments = obj.configureLogger(obj.name,varargin);
      obj.cvorb_arguments = varargin;
      
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.install();
      end
      
      obj.binPath = {which('localFeatures.mex.cvOrb')};
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
        [frames] = localFeatures.mex.cvOrb(img,obj.cvorb_arguments{:});
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        [frames descriptors] = mex.cvOrb(img,obj.cvorb_arguments{:});
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
        frames,obj.cvorb_arguments{:});
      timeElapsed = toc(startTime);
      
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:}) ';'...
              helpers.cell2str(obj.cvorb_arguments)];
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
      srclist = {fullfile(path,'cvOrb.cpp')};
      flags = {[OpenCVInstaller.MEXFLAGS ' ' VlFeatInstaller.MEXFLAGS ]};
    end
  end
end
