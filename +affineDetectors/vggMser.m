% This class implements the genericDetector interface. The implementation
% wraps around the vgg implementation of MSER

classdef vggMser < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for the vggMser
    % binary accepts. See the binary help for explanation.

    es  % Ellipse scale
    per % Maximum relative area
    ms  % Minimum size of output region
    mm  % Minimum margin

    binPath
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
      opts.es = 1.0;
      opts.per = 0.01;
      opts.ms = 30;
      opts.mm = 10;
      opts = vl_argparse(opts,varargin);

      obj.es = opts.es;
      obj.per = opts.per;
      obj.ms = opts.ms;
      obj.mm = opts.mm;

      % Check platform dependence
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      machineType = computer();
      binPath = '';
      switch(machineType)
        case  {'GLNX86','GLNXA64'}
          binPath = fullfile(cwd,vggMser.rootInstallDir,'mser.ln');
        case  {'PCWIN','PCWIN64'}
          binPath = fullfile(cwd,vggMser.rootInstallDir,'mser.exe');
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by vggMser',...
                                machineType);
      end
      obj.binPath = binPath;
    end

    function frames = detectPoints(obj,img)
      if ~obj.isOk, frames = zeros(5,0); return; end

      if(size(img,3) > 1), img = rgb2gray(img); end

      tmpName = tempname;
      imgFile = [tmpName '.png'];
      featFile = [tmpName '.feat'];

      imwrite(img,imgFile);
      args = sprintf(' -t 2 -es %f -per %f -ms %d -mm %d -i "%s" -o "%s"',...
                     obj.es,obj.per,obj.ms,obj.mm,imgFile, featFile);
      binPath = obj.binPath;
      cmd = [binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, msg) ;
      end

      frames = obj.parseMserOutput(featFile);
      delete(imgFile); delete(featFile);
    end

  end

  properties (Constant)
    rootInstallDir = 'thirdParty/vggMser/';
    softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz';
  end

  methods (Static)
    function frames = parseMserOutput(featFile)
      fid = fopen(featFile,'r');
      if fid==-1
        error('Could not read file: %s\n',featFile);
      end
      [header,count] = fscanf(fid,'%f',2);
      if count~= 2,
        error('Invalid vgg mser output in: %s\n',featFile);
      end
      numPoints = header(2);
      %frames = zeros(5,numPoints);
      [frames,count] = fscanf(fid,'%f',[5 numPoints]);
      if count~=5*numPoints,
        error('Invalid mser output in %s\n',featFile);
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
