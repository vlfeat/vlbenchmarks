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

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      if ~obj.isOk, frames = zeros(5,0); return; end

      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end

      tmpName = tempname;
      framesFile = [tmpName '.feat'];

      args = ' -t 2';
      if obj.opts.es ~= -1
        args = sprintf('%s -es %f',args,obj.opts.es);
      end
      if obj.opts.per ~= -1
        args = sprintf('%s -per %f',args,obj.opts.per);
      end
      if obj.opts.ms ~= -1
        args = sprintf('%s -ms %d',args,obj.opts.ms);
      end
      if obj.opts.mm ~= -1
        args = sprintf('%s -mm %d',args,obj.opts.mm);
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
                          framesFile, 'Magnification', obj.opts.magnification, ...
                          'NoAngle', obj.opts.noAngle );
      end
      
      delete(framesFile);

      timeElapsed = toc(startTime);
      obj.debug('%d frames from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';'... 
              helpers.struct2str(obj.opts)];
    end
    
  end

  methods (Static)

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
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {vggMser.softwareUrl};
      dstPaths = {vggMser.rootInstallDir};
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
