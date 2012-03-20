% VGGAFFINE class to wrap around the VGG affine co-variant detectors.
%
%   obj = affineDetectors.vggAffine('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class implements the genericDetector interface and wraps around the
%   vgg implementation of harris and hessian affine detectors available at:
%   http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/extract_features2.tar.gz
%
%   The constructor call above takes the following options:
%
%   Detector:: ['hessian']
%     One of 'hessian' or 'harris' to select what type of corner detector to use
%
%   HarThresh:: [10]
%     Threshold for harris corner detection (only used when detector is 'harris')
%
%   HesThresh:: [200]
%     Threshold for hessian maxima detection (only used when detector is 'hessian')

classdef vggAffine < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % Properties below correspond to the binary downloaded
    % from vgg
    detectorType % 'hesaff' or 'haraff'
    harThresh     % See binary documentation
    hesThresh     % See binary documentation

    binPath
  end

  methods
    % The constructor is used to set the options for vggAffine
    function this = vggAffine(varargin)
      import affineDetectors.*;

      if ~vggAffine.isInstalled(),
        this.isOk = false;
        this.errMsg = 'vggAffine not found installed';
        return;
      end

      % Parse the passed options
      opts.detector= 'hessian';
      opts.harThresh = 10;
      opts.hesThresh = 200;
      opts = vl_argparse(opts,varargin);

      switch(lower(opts.detector))
        case 'hessian'
          this.detectorType = 'hesaff';
        case 'harris'
          this.detectorType = 'haraff';
        otherwise
          error('Invalid detector type: %s\n',opts.detector);
      end
      this.detectorName = [opts.detector '-affine(vgg)' ];
      this.harThresh = opts.harThresh;
      this.hesThresh = opts.hesThresh;

      % Check platform dependence
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      machineType = computer();
      binPath = '';
      switch(machineType)
        case  {'GLNX86'}
          binPath = fullfile(cwd,vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_32bit.ln');
        case {'GLNXA64'}
          binPath = fullfile(cwd,vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_64bit.ln');
        case  {'PCWIN','PCWIN64'}
          binPath = fullfile(cwd,vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_32bit.exe');
        otherwise
          this.isOk = false;
          this.errMsg = sprintf('Arch: %s not supported by vggAffine',...
                                machineType);
      end
      this.binPath = binPath;
    end

    function frames = detectPoints(this,img)
      if ~this.isOk, frames = zeros(5,0); return; end

      if(size(img,3) > 1), img = rgb2gray(img); end

      tmpName = tempname;
      imgFile = [tmpName '.png'];
      outFile = [tmpName '.png.' this.detectorType];

      imwrite(img,imgFile);
      args = sprintf(' -%s -harThres %f -hesThres %f -i "%s"',...
                     this.detectorType,this.harThresh,this.hesThresh,imgFile);
      binPath = this.binPath;
      cmd = [binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end

      frames = vl_ubcread(outFile,'format','oxford');
      delete(imgFile); delete(outFile); delete([outFile '.params']);
    end

  end

  properties (Constant)
    rootInstallDir = 'thirdParty/vggAffine/';
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/extract_features2.tar.gz';
  end

  methods (Static)

    function cleanDeps()
      import affineDetectors.*;

      fprintf('\nDeleting vggAffine from: %s ...\n',vggAffine.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggAffine.rootInstallDir);

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('Vgg affine installation deleted\n');
      else
        fprintf('Vgg affine not installed, nothing to delete\n');
      end

    end

    function installDeps()
      import affineDetectors.*;
      if vggAffine.isInstalled(),
        fprintf('Detector vggAffine is already installed\n');
        return
      end
      fprintf('Downloading vggAffine to: %s ...\n',vggAffine.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggAffine.rootInstallDir);

      try
        untar(vggAffine.softwareUrl,installDir);
      catch err
        warning('Error downloading from: %s\n',vggAffine.softwareUrl);
        fprintf('Following error was reported while untarring: %s\n',...
                 err.message);
      end

      fprintf('vggAffine download and install complete\n\n');
    end

    function response = isInstalled()
      import affineDetectors.*;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggAffine.rootInstallDir);
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
