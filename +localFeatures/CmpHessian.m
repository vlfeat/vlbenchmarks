classdef CmpHessian < localFeatures.GenericLocalFeatureExtractor  & ...
    helpers.GenericInstaller
% localFeatures.CmpHessian CMP Hessian Affine wrapper
%   localFeatures.CmpHessian() constructs new wrapper object of a binary
%   created by compilation of a source code available at:
%   http://cmp.felk.cvut.cz/~perdom1/code/hesaff.tar.gz
%
%   This detector depends on OpenCV library.
%
%   (No options available currently)
%
%   See also: helpers.OpenCVInstaller

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    BinPath; % Path to the detector binary
  end

  properties (Constant, Hidden)
    RootInstallDir = fullfile('data','software','cmpHessian','');
    SoftwareUrl = 'http://cmp.felk.cvut.cz/~perdom1/code/hesaff.tar.gz';
  end

  methods
    % The constructor is used to set the options for the cmp
    % hessian binary.
    function obj = CmpHessian(varargin)
      import localFeatures.*;
      obj.Name = 'CMP Hessian Affine';
      obj.DetectorName = obj.Name;
      obj.DescriptorName = 'CMP SIFT';
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          obj.BinPath = fullfile(CmpHessian.RootInstallDir,'hesaff');
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by CmpHessian',...
                                machineType);
      end
      varargin = obj.checkInstall(varargin);
      obj.configureLogger(obj.Name,varargin);
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
      img = imread(imagePath);
      tmpName = tempname;
      imgFile = [tmpName '.png'];
      featFile = [tmpName '.png.hesaff.sift'];

      imwrite(img,imgFile);
      args = sprintf(' "%s" ',imgFile);
      cmd = [obj.BinPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      [frames descriptors] = vl_ubcread(featFile,'format','oxford');
      delete(featFile);
      
      timeElapsed = toc(startTime);
      obj.debug(sprintf('Features from image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = helpers.fileSignature(obj.BinPath);
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {CmpHessian.SoftwareUrl};
      dstPaths = {CmpHessian.RootInstallDir};
    end

    function deps = getDependencies(obj)
      deps = {helpers.Installer() helpers.VlFeatInstaller('0.9.14')...
        helpers.OpenCVInstaller()};
    end

    function compile(obj)
      error('Not implemented.');
    end
    
    function res = isCompiled(obj)
      res = true;
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
