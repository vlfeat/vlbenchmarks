classdef HarrisScaleSelect < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller

  properties (SetAccess=private, GetAccess=public)
    Opts = struct( ...
        'localize', 0, ...
        'NoScales', 61, ...
        'sigmamin', 1.26, ...
        'sigmamax', -1, ...
        'Hthres', 1500 ...
    )
  end

  properties (Constant, Hidden)
    % Installation directory
    RootInstallDir = fullfile('data','software');
    CodeDir = fullfile('data','software','diku-dtu_detectors');
    % URL for dataset tarballs
    CodeUrl = 'http://imm.dtu.dk/~abll/files/diku-dtu_detectors.tar.gz';
  end


  methods
    function obj = HarrisScaleSelect(varargin)
      import helpers.*;
      obj.Name = 'Harris with scale selection';
      varargin = obj.checkInstall(varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts, varargin);
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

      frames = harrisscaleselect(img, obj.Opts)';
      frames([1,2],:) = frames([2,1],:);
      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.struct2str(obj.Opts),';',...
        helpers.fileSignature(obj.CodeDir, 'harrisscaleselect.m'), ...
        mfilename('fullpath')];
    end

    function setup(obj)
      if(~exist('harrisscaleselect.m', 'file')),
        fprintf('Adding HarrisScaleSelect to path.\n');
        addpath(obj.CodeDir)
      end
    end

    function unload(obj)
      fprintf('Removing HarrisScaleSelect from path.\n');
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
