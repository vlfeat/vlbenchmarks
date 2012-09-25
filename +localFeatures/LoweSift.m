classdef LoweSift < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% LOWESIFT 
%
% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    BinPath
  end

  properties (Constant, Hidden)
    Url = 'http://www.cs.ubc.ca/~lowe/keypoints/siftDemoV4.zip';
    InstallDir = fullfile('data','software','loweSift','');
    ExecDir = fullfile(localFeatures.LoweSift.InstallDir,'siftDemoV4')
  end

  methods
    function obj = LoweSift(varargin)
      import localFeatures.*;
      obj.Name = 'Lowe SIFT';
      varargin = obj.checkInstall(varargin);
      obj.configureLogger(obj.Name,varargin);
      execDir = LoweSift.ExecDir;
      obj.BinPath = {fullfile(execDir, 'sift.m') ...
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
        cd(LoweSift.ExecDir);
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

    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.BinPath{:});
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer()};
    end

    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {LoweSift.Url};
      dstPaths = {LoweSift.InstallDir};
    end
  end
end
