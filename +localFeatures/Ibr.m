classdef Ibr < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.Ibr Intensity extrema-based region detector
%   localFeatures.Ibr('OptionName',OptionValue,...) Constructs wrapper around
%   intensity extrema-based detector binary [1] [2] used is downlaoded from:
%
%   http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/ibr.ln.gz
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binary is avaialable.
%
%   This detector supports the following options:
%
%   ScaleFactor:: [binary default]
%
%   NumberOfRegions:: [binary default]
%     Number of detected regions.
%
%   StabilityThreshold:: [binary default]
%
%   OverlapThreshold:: [binary default]
%
%   REFERENCES
%   [1] T. Tuytelaars, L. Van Gool. Wide baseline stereo matching based on
%   local, affinely invariant regions. BMVC, 412-425, 2000.
%
%   [2] T. Tuytelaars, L. Van Gool. Matching Widely Seprated Views based on
%   Affine Invariant Regions. IJCV 59(1):61-85, 2004.

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'scalefactor', -1,...
      'numberofregions', -1,...
      'stabilitythreshold', -1,...
      'overlapthreshold', -1);
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','ibr','');
    BinPath = fullfile(localFeatures.Ibr.rootInstallDir,'ibr.ln');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/ibr.ln.gz';
  end

  methods
    function obj = Ibr(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
          error('Arch: %s not supported by EBR',machineType);
      end
      obj.Name = 'IBR';
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      % Parse the passed options
      obj.Opts = vl_argparse(obj.Opts,varargin);
    end

    function [frames] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      obj.info('Computing frames of image %s.',getFileName(imagePath));

      tmpName = tempname;
      framesFile = [tmpName '.feat'];
      fields = fieldnames(obj.Opts);
      args = '';
      for i = numel(fields)
        field = fields{i};
        val = obj.Opts.(field);
        if val >= 0
          args = strcat(args,' -',field,' ', num2str(val));
        end
      end
      args = sprintf('%s "%s" "%s"',...
                     args, imagePath, framesFile);
      cmd = [obj.BinPath ' ' args];
      obj.debug('Executing: %s',cmd);
      startTime = tic;
      [status,msg] = system(cmd,'-echo');
      if status ~= 1
        error('%d: %s: %s', status, cmd, msg) ;
      end
      frames = localFeatures.helpers.readFramesFile(framesFile);
      delete(framesFile);
      timeElapsed = toc(startTime);
      obj.debug('%d frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath) ';'... 
              helpers.struct2str(obj.Opts)];
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {Ibr.softwareUrl};
      dstPaths = {Ibr.rootInstallDir};
    end
    
    function compile(obj)
      import localFeatures.*;
      % When unpacked, ibr is not executable
      helpers.setFileExecutable(Ibr.BinPath);
    end
  end
end
