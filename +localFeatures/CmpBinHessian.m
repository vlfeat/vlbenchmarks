classdef CmpBinHessian < localFeatures.GenericLocalFeatureExtractor  & ...
    helpers.GenericInstaller
% CMPBINHESSIAN wrapper around the CMP Hessian Affine detector implementation
%   CMPBINHESSIAN() Constructs an object which wraps around Hessian Affine 
%   detector [1] binary available at:
%   http://cmp.felk.cvut.cz/~perdom1/code/haff_cvpr09
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binaries are avaialable.
%
%   (No options available currently)
%
%   REFERENCES
%   [1] M. Perdoch, O. Chum and J. Matas: Efficient Representation of Local
%   Geometry for Large Scale Object Retrieval. CVPR, 9-16, 2009

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    binPath
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','cmpBinHessian','');
    url = 'http://cmp.felk.cvut.cz/~perdom1/code/haff_cvpr09';
    binName = 'haff_cvpr09';
    supportedImageFormats = {'.ppm','.pgm'};
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = CmpBinHessian(varargin)
      import localFeatures.*;
      obj.name = 'CMP Hessian Affine (bin)';
      obj.detectorName = obj.name;
      obj.descriptorName = 'CMP SIFT (bin)';
      if ~obj.isInstalled(),
        obj.warn('CmpBinHessian not found installed');
        obj.install();
      end
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNXA64'}
          obj.binPath = fullfile(obj.rootInstallDir,obj.binName);
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by CmpBinHessian',...
                                machineType);
      end
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.*;

      [frames descriptors] = obj.loadFeatures(origImagePath,true);
      if numel(frames) > 0; return; end;
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(origImagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(origImagePath));
      end
      % Write image in correct format
      [imagePath imIsTmp] = helpers.ensureImageFormat(origImagePath, ...
        obj.supportedImageFormats);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      featFile = [imagePath '.hesaff.sift'];
      args = sprintf(' "%s" ',imagePath);
      cmd = [obj.binPath ' ' args];
      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      [frames descriptors] = vl_ubcread(featFile,'format','oxford');
      delete(featFile);
      if imIsTmp, delete(imagePath); end;
      timeElapsed = toc(startTime);
      obj.debug(sprintf('Frames of image %s computed in %gs',...
        getFileName(origImagePath),timeElapsed));
      obj.storeFeatures(origImagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.binPath);
    end
  end

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.15')};
    end

    function compile()
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

    function res = isCompiled()
      import localFeatures.*;
      bin = fullfile(CmpBinHessian.rootInstallDir,...
        CmpBinHessian.binName);
      res = exist(bin,'file');
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
