classdef VggAffine < localFeatures.GenericLocalFeatureExtractor ...
    & helpers.GenericInstaller
% localFeatures.VggAffine VGG affine co-variant detectors wrapper
%   localFeatures.VggAffine('Option','OptionValue',...) Constructs the object
%   of the wrapper.
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binaries are avaialable.
%
%   The constructor call above takes the following options:
%
%   Detector:: 'hesaff'
%     One of {'hesaff', 'haraff', 'heslap', 'harlap','har'} which are
%     supported by the binary:
%     ./data/software/vggAffine/extract_features.ln

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'detector', 'hesaff',...
      'threshold', -1);
  end
  properties (Constant)
    ValidDetectors = {'hesaff', 'haraff', 'heslap', 'harlap','har'};
  end

  properties (Constant, Hidden)
    BinDir = fullfile('data','software','vggAffine','');
    DetBinPath = fullfile(localFeatures.VggAffine.BinDir,'h_affine.ln');
    DetUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/h_affine.ln.gz';
  end

  methods
    % The constructor is used to set the options for VggAffine
    function obj = VggAffine(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
        error('Binary not available for arch. %s.',machineType);
      end
      varargin = obj.checkInstall(varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      if ~ismember(obj.Opts.detector, obj.ValidDetectors)
        obj.error('Invalid detector');
      end
      obj.Name = 'VGG Affine';
      obj.ExtractsDescriptors = false;
      obj.SupportedImgFormats = {'.png','.ppm','.pgm'};
      obj.configureLogger(obj.Name,varargin);
    end

    function frames = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.*;

      [frames descriptors] = obj.loadFeatures(origImagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      obj.info('Computing frames of image %s.',getFileName(origImagePath));
      
      % Check whether image is of supported format
      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end

      tmpName = tempname;
      framesFile = [tmpName '.' obj.Opts.detector];
      detArgs = '';
      if obj.Opts.threshold >= 0
        detArgs = sprintf('-thres %f ',obj.Opts.threshold);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, obj.Opts.detector,...
                     imagePath,framesFile);

      detCmd = [obj.DetBinPath ' ' detArgs];
      obj.debug('Executing: %s',detCmd);
      startTime = tic;
      [status,msg] = system(detCmd);
      timeElapsed = toc(startTime);
      if status
        error('%d: %s: %s', status, detCmd, msg) ;
      end
      frames = helpers.readFramesFile(framesFile);
      delete(framesFile);
      if imIsTmp, delete(imagePath); end;
      obj.debug('%d Features from image %s computed in %gs',...
        size(frames,2),getFileName(origImagePath),timeElapsed);
      obj.storeFeatures(origImagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.DetBinPath) ... 
        helpers.struct2str(obj.Opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods  (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {VggAffine.DetUrl};
      dstPaths = {VggAffine.BinDir};
    end

    function compile(obj)
      import localFeatures.*;
      % When unpacked, binaries are not executable
      helpers.setFileExecutable(VggAffine.DetBinPath);
    end

    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.13')};
    end
  end
end
