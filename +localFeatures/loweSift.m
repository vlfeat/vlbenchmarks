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
      
      obj.detectorName = 'Lowe SIFT';
      obj.configureLogger(obj.detectorName,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.')
        obj.installDeps();
      end
      
      execDir = loweSift.dir;
      obj.binPath = {fullfile(execDir, 'sift.m') fullfile(execDir, 'sift')};
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath, true);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      curDir = pwd;
      imageName = getFileName(imagePath); 
      
      % In case image is not in grayscale convert it
      img = imread(imagePath);
      if ndims(img) == 3
        img = rgb2gray(img);
        imagePath = [tempname '.pgm'];
        imwrite(img, imagePath);
      end
      clear img;
      
      if imagePath(1) ~= filesep
        imagePath = fullfile(pwd,imagePath);
      end
      
      obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      
      try
        cd(loweSift.dir);
        [img descriptors frames] = sift(imagePath);
      catch err
        cd(curDir);
        throw(err);
      end
      
      cd(curDir);
      
      % Convert the frames to Matlab coordinate system
      descriptors = descriptors';
      frames = frames';
      frames(1:2,:) = frames([2 1],:) + 1;
      frames(4,:) = pi/2 - frames(4,:);
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        imageName,timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
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
