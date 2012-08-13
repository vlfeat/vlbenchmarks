% CMPHESSIAN class to wrap around the CMP Hessian Affine detector implementation
%
%   obj = localFeatures.cmpHessian('Option','OptionValue',...);
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

classdef cmpHessian < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the cmp hessian
    % binary accepts. See the binary help for explanation.
    binPath
  end
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','cmpHessian','');
    softwareUrl = 'http://cmp.felk.cvut.cz/~perdom1/code/hesaff.tar.gz';
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = cmpHessian(varargin)
      import localFeatures.*;
      obj.detectorName = 'CMP Hessian';
      if ~cmpHessian.isInstalled(),
        obj.isOk = false;
        warning('cmpHessian not found installed');
        cmpHessian.installDeps();
      end

      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          obj.binPath = fullfile(cmpHessian.rootInstallDir,'hesaff');
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by cmpHessian',...
                                machineType);
      end
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      Log.info(obj.detectorName,...
        sprintf('computing frames for image %s.',getFileName(imagePath)));
      
      img = imread(imagePath);
      if ~obj.isOk, frames = zeros(5,0); descriptors = zeros(128,0); return; end

      if(size(img,3) > 1), img = rgb2gray(img); end

      tmpName = tempname;
      imgFile = [tmpName '.png'];
      featFile = [tmpName '.png.hesaff.sift'];

      imwrite(img,imgFile);
      args = sprintf(' "%s" ',imgFile);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      [frames descriptors] = vl_ubcread(featFile,'format','oxford');
      delete(featFile);
      
      timeElapsed = toc(startTime);
      Log.debug(obj.detectorName, ... 
        sprintf('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.binPath);
    end
    
  end

  methods (Static)

    function cleanDeps()
      import localFeatures.*;

      fprintf('\nDeleting cmpHessian from: %s ...\n',cmpHessian.rootInstallDir);
      
      installDir = cmpHessian.rootInstallDir;

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('CMP hessian installation deleted\n');
      else
        fprintf('CMP hessian not installed, nothing to delete\n');
      end

    end

    function installDeps()
      import localFeatures.*;
      if cmpHessian.isInstalled(),
        fprintf('CMP hessian is already installed\n');
        return
      end
      fprintf('Downloading cmpHessian to: %s ...\n',cmpHessian.rootInstallDir);

      installDir = cmpHessian.rootInstallDir;

      try
        untar(cmpHessian.softwareUrl,installDir);
      catch err
        warning('Error downloading from: %s\n',cmpHessian.softwareUrl);
        fprintf('Following error was reported while untarring: %s\n',...
                 err.message);
      end

      fprintf('cmpHessian download complete, Manual compilation is needed to complete installation\n');
      fprintf('Goto directory: +localFeatures/%s, and run the makefile to complete the installation\n',...
              cmpHessian.rootInstallDir);
    end

    function response = isInstalled()
      import localFeatures.*;
      installDir = cmpHessian.rootInstallDir;
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
