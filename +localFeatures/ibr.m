% IBR Intensity extrema based detector

classdef ibr < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
    opts = struct(...
      'scalefactor', -1,...
      'numberofregions', -1,...
      'stabilitythreshold', -1,...
      'overlapthreshold', -1);
  end
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','ibr','');
    binPath = fullfile(localFeatures.ibr.rootInstallDir,'ibr.ln');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/ibr.ln.gz';
  end

  methods
    function obj = ibr(varargin)
      import localFeatures.*;
      import helpers.*;
      obj.name = 'IBR';
      obj.detectorName = obj.name;
      % Parse the passed options
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.name,varargin);
      if ~obj.isInstalled(),
        obj.warn('IBR not found installed');
        obj.install();
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

      fields = fieldnames(obj.opts);
      args = '';
      for i = numel(fields)
        field = fields{i};
        val = obj.opts.(field);
        if val >= 0
          args = strcat(args,' -',field,' ', num2str(val));
        end
      end
      
      
      args = sprintf('%s "%s" "%s"',...
                     args, imagePath, framesFile);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd,'-echo');
      if status ~= 1
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
      sign = [helpers.fileSignature(obj.binPath) ';'... 
              helpers.struct2str(obj.opts)];
    end
    
  end

  methods (Static)
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {ibr.softwareUrl};
      dstPaths = {ibr.rootInstallDir};
    end
    
    function compile()
      import localFeatures.*;
      % When unpacked, ibr is not executable
      helpers.setFileExecutable(ibr.binPath);
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
