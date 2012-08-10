% VGGMSER class to wrap around the VGG MSER implementation
%
%   obj = affineDetectors.vggMser('Option','OptionValue',...);
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

classdef vggMser < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the vggMser
    % binary accepts. See the binary help for explanation.
    binPath
  end
  
    properties (Constant)
    rootInstallDir = fullfile('data','software','vggMSER','');
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz';
  end

  methods
    % The constructor is used to set the options for the vgg
    % mser binary.
    function obj = vggMser(varargin)
      import affineDetectors.*;
      obj.detectorName = 'MSER(vgg)';
      if ~vggMser.isInstalled(),
        obj.isOk = false;
        obj.errMsg = 'vggMser not found installed';
        return;
      end

      % Parse the passed options
      opts.es = -1;
      opts.per = -1;
      opts.ms = -1;
      opts.mm = -1;
      obj.opts.noAngle = false;
      obj.opts.magnification = -1;
      obj.opts = vl_argparse(opts,varargin);

      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          obj.binPath = fullfile(vggMser.rootInstallDir,'mser.ln');
        case  {'PCWIN','PCWIN64'}
          obj.binPath = fullfile(vggMser.rootInstallDir,'mser.exe');
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by vggMser',...
                                machineType);
      end
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      if ~obj.isOk, frames = zeros(5,0); return; end

      tmpName = tempname;
      framesFile = [tmpName '.feat'];

      args = ' -t 2';
      if obj.opts.es ~= -1
        args = sprintf('%s -es %f',args,obj.es);
      end
      if obj.opts.per ~= -1
        args = sprintf('%s -per %f',args,obj.per);
      end
      if obj.opts.ms ~= -1
        args = sprintf('%s -ms %d',args,obj.ms);
      end
      if obj.opts.mm ~= -1
        args = sprintf('%s -mm %d',args,obj.mm);
      end
      args = sprintf('%s -i "%s" -o "%s"',...
                     args, imagePath, framesFile);
      cmd = [obj.binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end
      
      if nargout == 1
        frames = obj.parseMserOutput(framesFile);
      else
        [ frames descriptors ] = helpers.vggCalcSiftDescriptor( imagePath, ...
                          framesFile, obj.opts.magnification, obj.opts.noAngle );
      end
      
      delete(imagePath); delete(framesFile);
    end

    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'... 
              num2str(obj.opts.es) ';'...
              num2str(obj.opts.per) ';'...
              num2str(obj.opts.ms) ';'...
              num2str(obj.opts.mm) ';'...
              num2str(obj.opts.magnification) ';' ... 
              num2str(obj.opts.noAngle) ';' ... 
              ];
    end
    
  end

  methods (Static)

    function cleanDeps()
      import affineDetectors.*;

      fprintf('\nDeleting vggMser from: %s ...\n',vggMser.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggMser.rootInstallDir);

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('Vgg mser installation deleted\n');
      else
        fprintf('Vgg mser not installed, nothing to delete\n');
      end

    end

    function frames = parseMserOutput(framesFile)
      fid = fopen(framesFile,'r');
      if fid==-1
        error('Could not read file: %s\n',framesFile);
      end
      [header,count] = fscanf(fid,'%f',2);
      if count~= 2,
        error('Invalid vgg mser output in: %s\n',framesFile);
      end
      numPoints = header(2);
      %frames = zeros(5,numPoints);
      [frames,count] = fscanf(fid,'%f',[5 numPoints]);
      if count~=5*numPoints,
        error('Invalid mser output in %s\n',framesFile);
      end

      % Transform the frame properly
      frames(1:2,:) = frames(1:2,:) + 1;
      C = frames(3:5,:);
      den = C(1,:) .* C(3,:) - C(2,:) .* C(2,:) ;
      S = [C(3,:) ; -C(2,:) ; C(1,:)] ./ den([1 1 1], :) ;
      frames(3:5,:) = S;

      fclose(fid);

    end

    function installDeps()
      import affineDetectors.*;
      if vggMser.isInstalled(),
        fprintf('Detector vggMser is already installed\n');
        return
      end
      fprintf('Downloading vggMser to: %s ...\n',vggMser.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggMser.rootInstallDir);

      try
        untar(vggMser.softwareUrl,installDir);
      catch err
        warning('Error downloading from: %s\n',vggMser.softwareUrl);
        fprintf('Following error was reported while untarring: %s\n',...
                 err.message);
      end

      fprintf('vggMser download and install complete\n\n');
    end

    function response = isInstalled()
      import affineDetectors.*;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggMser.rootInstallDir);
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
