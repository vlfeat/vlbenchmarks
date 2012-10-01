classdef CmpBinHessian < localFeatures.GenericLocalFeatureExtractor  & ...
    helpers.GenericInstaller
% localFeatures.CmpBinHessian CMP Hessian Affine binary wrapper
%   localFeatures.CmpBinHessian() Constructs an object which wraps around
%   Hessian Affine detector [1] binary available at:
%   http://cmp.felk.cvut.cz/~perdom1/code/haff_cvpr09
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binaries are avaialable.
%
%   (No options currently available)
%
%   REFERENCES
%   [1] M. Perdoch, O. Chum and J. Matas: Efficient Representation of Local
%   Geometry for Large Scale Object Retrieval. CVPR, 9-16, 2009

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    BinPath
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','cmpBinHessian','');
    url = 'http://cmp.felk.cvut.cz/~perdom1/code/haff_cvpr09';
    binName = 'haff_cvpr09';
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = CmpBinHessian(varargin)
      import localFeatures.*;
      obj.Name = 'CMP Hessian Affine (bin)';
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNXA64'}
          obj.BinPath = fullfile(obj.rootInstallDir,obj.binName);
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by CmpBinHessian',...
                                machineType);
      end
      varargin = obj.checkInstall(varargin);
      obj.configureLogger(obj.Name,varargin);
      obj.SupportedImgFormats = {'.ppm','.pgm'};
    end

    function [frames descriptors] = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.*;

      [frames descriptors] = obj.loadFeatures(origImagePath,true);
      if numel(frames) > 0; return; end;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(origImagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(origImagePath));
      end
      % Write image in correct format
      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      featFile = [imagePath '.hesaff.sift'];
      args = sprintf(' "%s" ',imagePath);
      cmd = [obj.BinPath ' ' args];
      obj.debug('Executing: %s',cmd);
      startTime = tic;
      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      [frames descriptors] = vl_ubcread(featFile,'format','oxford');
      delete(featFile);
      if imIsTmp, delete(imagePath); end;
      timeElapsed = toc(startTime);
      obj.debug(sprintf('%d Frames of image %s computed in %gs',...
        size(frames,2),getFileName(origImagePath),timeElapsed));
      obj.storeFeatures(origImagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.BinPath);
    end
  end

  methods (Access=protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15')};
    end

    function compile(obj)
      import localFeatures.*;
      import helpers.*;
      filePath = helpers.downloadFile(CmpBinHessian.url,...
        CmpBinHessian.rootInstallDir);
      if isempty(filePath)
        error('Unable to download %s',CmpBinHessian.url)
      end
      % Set executable flags
      helpers.setFileExecutable(filePath);
    end

    function res = isCompiled(obj)
      import localFeatures.*;
      bin = fullfile(CmpBinHessian.rootInstallDir,...
        CmpBinHessian.binName);
      res = exist(bin,'file');
    end
  end
end
