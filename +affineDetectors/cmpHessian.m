% CMPHESSIAN class to wrap around the CMP Hessian Affine detector implementation
%
%   obj = affineDetectors.cmpHessian('Option','OptionValue',...);
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

classdef cmpHessian < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the cmp hessian
    % binary accepts. See the binary help for explanation.

    binPath
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = cmpHessian(varargin)
      import affineDetectors.*;
      obj.detectorName = 'CMP Hessian';
      if ~cmpHessian.isInstalled(),
        obj.isOk = false;
        obj.errMsg = 'cmpHessian not found installed';
        return;
      end

      % Parse the passed options
      %opts.es = 1.0;
      %opts.per = 0.01;
      %opts.ms = 30;
      %opts.mm = 10;
      %opts = vl_argparse(opts,varargin);

      % Check platform dependence
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      machineType = computer();
      binPath = '';
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          binPath = fullfile(cwd,cmpHessian.rootInstallDir,'hesaff');
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by cmpHessian',...
                                machineType);
      end
      obj.binPath = binPath;
    end

    function frames = detectPoints(obj,img)
      if ~obj.isOk, frames = zeros(5,0); return; end

      if(size(img,3) > 1), img = rgb2gray(img); end

      tmpName = tempname;
      imgFile = [tmpName '.png'];
      featFile = [tmpName '.png.hesaff.sift'];

      imwrite(img,imgFile);
      args = sprintf(' "%s" ',imgFile);
      binPath = obj.binPath;
      cmd = [binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end

      frames = vl_ubcread(featFile,'format','oxford');
      delete(imgFile); delete(featFile);
    end

  end

  properties (Constant)
    rootInstallDir = 'thirdParty/cmpHessian/';
    softwareUrl = 'http://cmp.felk.cvut.cz/~perdom1/code/hesaff.tar.gz';
  end

  methods (Static)

    function cleanDeps()
      import affineDetectors.*;

      fprintf('\nDeleting cmpHessian from: %s ...\n',cmpHessian.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,cmpHessian.rootInstallDir);

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('CMP hessian installation deleted\n');
      else
        fprintf('CMP hessian not installed, nothing to delete\n');
      end

    end

    function installDeps()
      import affineDetectors.*;
      if cmpHessian.isInstalled(),
        fprintf('CMP hessian is already installed\n');
        return
      end
      fprintf('Downloading cmpHessian to: %s ...\n',cmpHessian.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,cmpHessian.rootInstallDir);

      try
        untar(cmpHessian.softwareUrl,installDir);
      catch err
        warning('Error downloading from: %s\n',cmpHessian.softwareUrl);
        fprintf('Following error was reported while untarring: %s\n',...
                 err.message);
      end

      fprintf('cmpHessian download complete, Manual compilation is needed to complete installation\n');
      fprintf('Goto directory: +affineDetectors/%s, and run the makefile to complete the installation\n',...
              cmpHessian.rootInstallDir);
    end

    function response = isInstalled()
      import affineDetectors.*;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,cmpHessian.rootInstallDir);
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
