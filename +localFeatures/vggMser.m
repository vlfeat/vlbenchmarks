% VGGMSER class to wrap around the VGG MSER implementation
%
%   obj = localFeatures.vggMser('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class implements the genericDetector interface and wraps around the
%   vgg implementation of MSER detectors available at:
%   http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz
%
%   The constructor call above takes the following options (see the vgg
%   mser binary for complete interpretation of these options):
%
%   ES:: [1.0]
%     Scale of the ellipse
%
%   PER:: [0.01]
%     Maximum relative area
%
%   MS:: [30]
%     Minimum size of output region
%
%   MM:: [10]
%     Minimum margin
%
%   noAngle:: [false]
%     Compute rotation variant descriptors if true (no rotation esimation)
%
%   Magnification:: [binary default]
%     Magnification of the measurement region for the descriptor
%     calculation.

classdef vggMser < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the vggMser
    % binary accepts. See the binary help for explanation.
    binPath
    opts
  end
  
    properties (Constant)
    rootInstallDir = fullfile('data','software','vggMSER','');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz';
  end

  methods
    % The constructor is used to set the options for the vgg
    % mser binary.
    function obj = vggMser(varargin)
      import localFeatures.*;
      import helpers.*;
      obj.detectorName = 'MSER(vgg)';

      % Parse the passed options
      obj.opts.es = -1;
      obj.opts.per = -1;
      obj.opts.ms = -1;
      obj.opts.mm = -1;
      obj.opts.noAngle = false;
      obj.opts.magnification = 3;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      
      obj.configureLogger(obj.detectorName,varargin);
      
      if ~obj.isInstalled(),
        obj.isOk = false;
        obj.warn('vggMser not found installed');
        obj.installDeps();
      end
      
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          obj.binPath = fullfile(vggMser.rootInstallDir,'mser.ln');
        case  {'PCWIN','PCWIN64'}
          obj.binPath = fullfile(vggMser.rootInstallDir,'mser.exe');
        otherwise
          error('Arch: %s not supported by vggMser',machineType);
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

      args = ' -t 2';

      fields = fieldnames(obj.opts);
      for field = fields
        val = getfield(obj.opts,field{:});
        if val >= 0
          args = strcat(args,' -',field,' ', num2str(val));
        end
      end
      
      args = sprintf('%s -i "%s" -o "%s"',...
                     args, imagePath, framesFile);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      frames = localFeatures.helpers.readFramesFile(framesFile);
      
      delete(framesFile);

      timeElapsed = toc(startTime);
      obj.debug('%d frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, []);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';'... 
              helpers.struct2str(obj.opts)];
    end
    
  end

  methods (Static)
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {vggMser.softwareUrl};
      dstPaths = {vggMser.rootInstallDir};
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
