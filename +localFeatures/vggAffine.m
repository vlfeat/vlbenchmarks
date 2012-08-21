% VGGAFFINE class to wrap around the VGG affine co-variant detectors.
%
%   obj = localFeatures.vggAffine('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   obj class implements the genericDetector interface and wraps around the
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

classdef vggAffine < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    % Properties below correspond to the binary downloaded
    % from vgg
    opts
    binPath
  end
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','vggAffine','');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/extract_features2.tar.gz';
  end
  
  methods
    % The constructor is used to set the options for vggAffine
    function obj = vggAffine(varargin)
      import localFeatures.*;
      import helpers.*;
      if ~vggAffine.isInstalled(),
        obj.isOk = false;
        warn('vggAffine not found installed');
        vggAffine.installDeps();
      end

      % Parse the passed options
      obj.opts.detector= 'hessian';
      obj.opts.harThresh = 1000; % original 10, documented 1000
      obj.opts.hesThresh = 500; % original 200, documented 500
      obj.opts.noAngle = false;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);

      switch(lower(obj.opts.detector))
        case 'hessian'
          obj.opts.detectorType = 'hesaff';
        case 'harris'
          obj.opts.detectorType = 'haraff';
        otherwise
          error('Invalid detector type: %s\n',opts.detector);
      end
      obj.detectorName = [obj.opts.detector '-affine(vgg)' ];
      
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86'}
          obj.binPath = fullfile(vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_32bit.ln');
        case {'GLNXA64'}
          obj.binPath = fullfile(vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_64bit.ln');
        case  {'PCWIN','PCWIN64'}
          obj.binPath = fullfile(vggAffine.rootInstallDir,'extract_features',...
                             'extract_features_32bit.exe');
        otherwise
          obj.isOk = false;
          warning('Arch: %s not supported by vggAffine',machineType);
      end
      obj.configureLogger(obj.detectorName,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;

      if ~obj.isOk, frames = zeros(5,0); return; end

      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end
      
      tmpName = tempname;
      outFile = [tmpName '.' obj.opts.detectorType];
      tempImageCreated = false;
      
      [path filename ext] = fileparts(imagePath);
      % Convert jpeg images to png (jpeg not supported).
      if strcmp(ext,'.jpg') || strcmp(ext,'.jpeg')
        obj.debug(obj.detectorName,sprintf('converting jpeg->png.'));
        im = imread(imagePath);
        imagePath = [tmpName '.png'];
        imwrite(im,imagePath);
        tempImageCreated = true;
        clear im;
      end
      
      if nargout == 2 
        desc_param='-sift'; 
        outFile = strcat(outFile, '.sift');
      else 
        desc_param = ''; 
      end;

      args = sprintf(' -o1 "%s" -%s -harThres %f -hesThres %f -i "%s" %s',...
                     outFile, obj.opts.detectorType, obj.opts.harThresh,...
                     obj.opts.hesThresh, imagePath, desc_param);
      if obj.opts.noAngle
        args = strcat(args,' -noangle');
      end
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end

      [frames descriptors] = vl_ubcread(outFile,'format','oxford');
      delete(outFile); delete([outFile '.params']);
      if tempImageCreated, delete(imagePath); end;

      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';' ... 
              obj.opts.detectorType ';' ... 
              num2str(obj.opts.harThresh) ';' ...
              num2str(obj.opts.hesThresh) ';' ...
              num2str(obj.opts.noAngle)];
    end

  end

  methods (Static)

    function cleanDeps()
      import localFeatures.*;

      fprintf('\nDeleting vggAffine from: %s ...\n',vggAffine.rootInstallDir);

      installDir = vggAffine.rootInstallDir;

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('Vgg affine installation deleted\n');
      else
        fprintf('Vgg affine not installed, nothing to delete\n');
      end

    end

    function installDeps()
      import localFeatures.*;
      if vggAffine.isInstalled(),
        fprintf('Detector vggAffine is already installed\n');
        return
      end
      fprintf('Downloading vggAffine to: %s ...\n',vggAffine.rootInstallDir);

      installDir = vggAffine.rootInstallDir;

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
      import localFeatures.*;
      installDir = vggAffine.rootInstallDir;
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
