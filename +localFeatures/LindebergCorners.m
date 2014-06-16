classdef LindebergCorners < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller

  properties (SetAccess=public, GetAccess=public)
    CodeDir;
    Opts;
  end

  properties (Constant, Hidden)
    % Installation directory
    RootInstallDir = fullfile('data','software','multiscale_harris');
    % URL for dataset tarballs
    CodeUrl = 'http://imm.dtu.dk/~abll/files/multiscale_harris.tar.gz';
  end


  methods
    function obj = LindebergCorners(varargin)
      obj.Name = 'Lindeberg Corners';
      obj.CodeDir = fullfile(obj.RootInstallDir, 'code');
      obj.Opts = struct('localization', 1);
      varargin = obj.checkInstall(varargin);
      obj.setup();
    end

    function [frames] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));

      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img); % If not already in uint8, then convert

      obj.Opts.localization
      frames = lindebergcorner(img, obj.Opts.localization)';
      frames([1,2],:) = frames([2,1],:);

      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.struct2str(obj.Opts),';',...
        helpers.fileSignature(obj.CodeDir, 'lindebergcorner.cpp'), ...
        helpers.fileSignature(obj.CodeDir, 'LocalMaxima3DFast.cpp'), ...
        helpers.fileSignature(obj.CodeDir, 'multiscaleharris.cpp'), ...
        helpers.fileSignature(obj.CodeDir, 'scale.cpp'), ...
        mfilename('fullpath')];
    end

    function setup(obj)
      if(~exist('lindebergcorner.m', 'file')),
        fprintf('Adding LindebergCorners to path.\n');
        addpath(obj.CodeDir)
      end
    end

    function unload(obj)
      fprintf('Removing LindebergCorners from path.\n');
      rmpath(obj.CodeDir)
    end

  end

  methods (Access=protected, Hidden)
    function [srclist flags]  = getMexSources(obj)
      srclist = {fullfile(obj.CodeDir, 'LocalMaxima3DFast.cpp')};
      flags = {''};
    end
  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      installDir = obj.RootInstallDir;
      dstPaths = {fullfile(installDir)};
      urls = {obj.CodeUrl};
    end
  end
end
