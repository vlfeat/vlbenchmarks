classdef ScaleSaliency < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'Nbins', 255,...
      'Sigma', 10,...
      'StartScale', 1,...
      'StopScale', 100,...
      'AA', true);
  end

  properties (Constant, Hidden)
    RootInstallDir = fullfile('data','software','scsaliency','');
    MatDir = fullfile(pwd,localFeatures.ScaleSaliency.RootInstallDir,'ScaleSaliency_Public','');
    UrlLnx = 'http://www.robots.ox.ac.uk/~timork/Saliency/ScaleSaliency_Public_linux_V1.5.tgz';
    UrlWin = 'http://www.robots.ox.ac.uk/~timork/Saliency/ScaleSaliency_Public_windows_V1.5.tgz';
  end
  
  methods
    function obj = ScaleSaliency(varargin)
      import helpers.*;
      obj.Name = 'ScaleSalilency';
      if ~ismember(computer,{'GLNX86','PCWIN'})
        error('Scale saliency is not supported on your architecture.');
      end
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end

    function frames = extractFeatures(obj, imagePath)
      import helpers.*;
      frames = obj.loadFeatures(imagePath, false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));
      img = imread(imagePath);
      div = 255/obj.Opts.Nbins;
      img = double(img)./div;
      curDir = pwd;
      cd(obj.MatDir);
      try
        frames = CalcScaleSaliency(uint8(img),obj.Opts.StartScale,...
          obj.Opts.StopScale, obj.Opts.Nbins, obj.Opts.Sigma,AA);
      catch err
        cd(curDir);
        throw(err);
      end
      cd(curDir);
      frames = frames(1:3,:);
      timeElapsed = toc(startTime);
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2), getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function signature = getSignature(obj)
      import helpers.*;
      signature = helpers.fileSignature(obj.BinPath);
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      switch computer
        case {'GLNX86'}
          urls = {ScaleSaliency.UrlLnx};
        case {'PCWIN'}
          urls = {ScaleSaliency.UrlWin};
        otherwise
          error('Not supported platform.');
      end
      dstPaths = {ScaleSaliency.RootInstallDir};
    end
  end
end
