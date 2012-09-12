% LOWESIFT 
%


classdef loweSift < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=public, GetAccess=public)
    binPath
  end

  properties (Constant)
    url = 'http://www.cs.ubc.ca/~lowe/keypoints/siftDemoV4.zip';
    installDir = fullfile('data','software','loweSift','');
    dir = fullfile(localFeatures.loweSift.installDir,'siftDemoV4')
  end
  
  methods

    function obj = loweSift(varargin)
      import localFeatures.*;
      obj.name = 'Lowe SIFT';
      obj.detectorName = obj.name;
      obj.descriptorName = obj.name;
      obj.configureLogger(obj.name,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.install();
      end
      
      execDir = loweSift.dir;
      obj.binPath = {fullfile(execDir, 'sift.m') ...
        fullfile(execDir, 'sift')};
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath, true);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      curDir = pwd;
      
      % In case image is not in grayscale convert it and save it
      img = imread(imagePath);
      if ndims(img) == 3
        img = rgb2gray(img);
        detImagePath = [tempname '.pgm'];
        imwrite(img, detImagePath);
      else
        detImagePath = imagePath;
      end
      clear img;
      
      % Check whether it is absolute path
      if detImagePath(1) ~= filesep
        detImagePath = fullfile(pwd,imagePath);
      end
      
      obj.info('Computing frames and descriptors of image %s.',...
        getFileName(imagePath));
      
      try
        cd(loweSift.dir);
        [img descriptors frames] = sift(detImagePath);
        cd(curDir);
      catch err
        cd(curDir);
        throw(err);
      end      

      % Convert the frames to Matlab coordinate system
      descriptors = descriptors';
      frames = frames';
      frames(1:2,:) = frames([2 1],:) + 1;
      frames(4,:) = pi/2 - frames(4,:);
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      obj.error('Descriptor calculation of provided frames not supported');
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath{:})];
    end
  end
  
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer()};
    end
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {loweSift.url};
      dstPaths = {loweSift.installDir};
    end
  end
end
