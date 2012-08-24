% EBR Edge based detector

classdef ebr < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','ebr','');
    binPath = fullfile(localFeatures.ebr.rootInstallDir,'ebr.ln');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/ebr.ln.gz';
  end

  methods
    function obj = ebr(varargin)
      import localFeatures.*;
      import helpers.*;
      obj.detectorName = 'EBR';
      
      obj.configureLogger(obj.detectorName,varargin);
      
      if ~obj.isInstalled(),
        obj.warn('ebr not found installed');
        obj.installDeps();
      end
      
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
          error('Arch: %s not supported by EBR',machineType);
      end
    end

    function [frames] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;

      frames = obj.loadFeatures(imagePath,false);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      obj.info('Computing frames of image %s.',getFileName(imagePath));

      tmpName = tempname;
      framesFile = [tmpName '.feat'];
      
      args = sprintf('"%s" "%s"',imagePath, framesFile);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd,'-echo');
      if status ~= 0
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      frames = localFeatures.helpers.readFramesFile(framesFile);
      
      delete(framesFile);

      timeElapsed = toc(startTime);
      obj.debug('%d frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, []);
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
      urls = {ebr.softwareUrl};
      dstPaths = {ebr.rootInstallDir};
    end
    
    function compile()
      import localFeatures.*;
      % When unpacked, ebr is not executable
      chmodCmd = sprintf('chmod +x %s',ebr.binPath);
      system(chmodCmd);
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
