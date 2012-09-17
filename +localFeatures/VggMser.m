classdef VggMser < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% VGGMSER class to wrap around the VGG MSER implementation
%   VGGMSER('Option','OptionValue',...) Construct and object which wraps
%   around a MSER detector [1] binary available at
%   http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binary is avaialable.
%
%   The constructor call above takes the following options (see the vgg
%   mser binary for complete interpretation of these options):
%
%   ES:: [binary default, 1.0]
%     Scale of the ellipse
%
%   PER:: [binary default, 0.01]
%     Maximum relative area
%
%   MS:: [binary default, 30]
%     Minimum size of output region
%
%   MM:: [binary default, 10]
%     Minimum margin
%
%   REFERENCES
%   [1] J. Matas, O. Chum, M. Urban and T. Pajdla. Robust wide-baseline 
%   stereo from maximally stable extremal regions. BMVC, 384-393, 2002.

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the VggMser
    % binary accepts. See the binary help for explanation.
    binPath
    opts = struct(...
      'es', -1,...
      'per', -1,...
      'ms', -1,...
      'mm', -1);
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','vggMSER','');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz';
  end

  methods
    % The constructor is used to set the options for the vgg
    % mser binary.
    function obj = VggMser(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          obj.binPath = fullfile(VggMser.rootInstallDir,'mser.ln');
        case  {'PCWIN','PCWIN64'}
          obj.binPath = fullfile(VggMser.rootInstallDir,'mser.exe');
        otherwise
          error('Arch: %s not supported by VggMser',machineType);
      end
      obj.name = 'VGG MSER';
      obj.detectorName = obj.name;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.name,varargin);
      % Parse the passed options
      obj.opts = vl_argparse(obj.opts,varargin);
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
      args = ' -t 2'; % Define the output type
      fields = fieldnames(obj.opts);
      for i = 1:numel(fields)
        val = obj.opts.(fields{i});
        if val >= 0
          args = [args,' -',fields{i},' ', num2str(val)];
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
      urls = {VggMser.softwareUrl};
      dstPaths = {VggMser.rootInstallDir};
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
