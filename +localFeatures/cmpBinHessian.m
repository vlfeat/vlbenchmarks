% cmpBinHessian class to wrap around the CMP Hessian Affine detector implementation
%
%   obj = localFeatures.cmpBinHessian('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class implements the genericDetector interface and wraps around the
%   cmp implementation of Hessian Affine detectors available at:
%   http://cmp.felk.cvut.cz/~perdom1/code/hesaff.tar.gz
%
%   The constructor call above takes the following options (see the cmp hessian
%   binary for complete interpretation of these options):
%
%   (No options available currently)

classdef cmpBinHessian < localFeatures.genericLocalFeatureExtractor  & ...
    helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
    binPath
  end
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','cmpBinHessian','');
    url = 'http://cmp.felk.cvut.cz/~perdom1/code/haff_cvpr09';
    binName = 'haff_cvpr09';
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = cmpBinHessian(varargin)
      import localFeatures.*;
      obj.name = 'CMP Hessian Affine (bin)';
      obj.detectorName = obj.name;
      obj.descriptorName = 'CMP SIFT (bin)';
      if ~obj.isInstalled(),
        obj.warn('cmpBinHessian not found installed');
        obj.installDeps();
      end

      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNXA64'}
          obj.binPath = fullfile(obj.rootInstallDir,obj.binName);
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by cmpBinHessian',...
                                machineType);
      end
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,true);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end
      
      featFile = [imagePath '.hesaff.sift'];
      
      args = sprintf(' "%s" ',imagePath);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      [frames descriptors] = vl_ubcread(featFile,'format','oxford');
      delete(featFile);
      
      timeElapsed = toc(startTime);
      obj.debug(sprintf('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      obj.error('Descriptor calculation of provided frames not supported');
    end
    
    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.binPath);
    end
    
  end

  methods (Static)
    
    function deps = getDependencies()
      deps = {helpers.Installer()};
    end
    
    function compile()
      import localFeatures.*;
      import helpers.*;
      filePath = helpers.downloadFile(cmpBinHessian.url,...
        cmpBinHessian.rootInstallDir);
      if isempty(filePath)
        error('Unable to download %s',cmpBinHessian.url)
      end
      
      % Set executable flags
      helpers.setFileExecutable(filePath);
    end
    
    function res = isCompiled()
      import localFeatures.*;
      bin = fullfile(cmpBinHessian.rootInstallDir,...
        cmpBinHessian.binName);
      res = exist(bin,'file');
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
