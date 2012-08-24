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

classdef cmpHessian < localFeatures.genericLocalFeatureExtractor  & ...
    helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
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
      if ~obj.isInstalled(),
        obj.isOk = false;
        obj.warn('cmpHessian not found installed');
        obj.installDeps();
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
      obj.configureLogger(obj.detectorName,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end
      
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
      obj.debug(obj.detectorName, ... 
        sprintf('Frames of image %s computed in %gs',...
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
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {cmpHessian.softwareUrl};
      dstPaths = {cmpHessian.rootInstallDir};
    end
    
    function deps = getDependencies()
      deps = {helpers.Installer() helpers.OpenCVInstaller()};
    end
    
    function compile()
      error('Not implemented.');
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
