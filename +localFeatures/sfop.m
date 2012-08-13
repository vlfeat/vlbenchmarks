% SFOP class to wrap around the SFOP detector implementation
%
%   obj = affineDetectors.sfop('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   obj class implements the genericDetector interface and wraps around
%   the implementation of SFOP available at:
%   http://www.ipb.uni-bonn.de/index.php?id=220#software
%
%   The options are documented in the SFOP code, which you can see at
%   +affineDetectors/thirdParty/sfop/sfop-0.9/matlab/sfopParams.m
%   (the above file only exists once you have installed all the third party
%   software using installDeps command)

classdef sfop < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % Properties below correspond to the binary downloaded
    % from vgg
    sfop_varargin % See SFOP documentation for parameters, in the file:
                  % sfop-0.9/matlab/sfopParams.m

  end

  methods
    % The constructor is used to set the options for vggAffine
    function obj = sfop(varargin)
      import affineDetectors.*;

      if ~obj.isInstalled(),
        obj.isOk = false;
        obj.errMsg = 'SFOP not found installed';
        return;
      end

      obj.sfop_varargin = varargin;
    end

    function frames = extractFrames(obj,imagePath)
      import helpers.*;
      if ~obj.isOk, frames = zeros(5,0); return; end

      startTime = tic;
      Log.info(obj.detectorName,...
        sprintf('computing frames for image %s.',getFileName(imagePath)));      

      tmpName = tempname;
      outFile = [tmpName '.points'];

      savePwd = pwd;
      cwd = fileparts(mfilename('fullpath'));
      sfop_varargin = obj.sfop_varargin;
      cd(fullfile(cwd,obj.rootInstallDir,'sfop-0.9','matlab'));
      sfop(imagePath,outFile,sfop_varargin{:});
      cd(savePwd);

      frames = affineDetectors.vggMser.parseMserOutput(outFile);
      % Above output uses the same output format as vggMser

      delete(outFile);
      
      timeElapsed = toc(startTime);
      Log.debug(obj.detectorName, ... 
        sprintf('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
    end
  end

  properties (Constant)
    rootInstallDir = 'thirdParty/sfop/';
    softwareUrl = 'http://www.ipb.uni-bonn.de/fileadmin/research/media/sfop/sfop-0.9.tar.gz';
  end

  methods (Static)

    function cleanDeps()
      import affineDetectors.*;

      fprintf('Deleting SFOP from: %s ...\n',sfop.rootInstallDir);

      cwd = fileparts(mfilename('fullpath'));
      installDir = fullfile(cwd,sfop.rootInstallDir);

      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('SFOP installation deleted\n');
      else
        fprintf('SFOP not installed, nothing to delete\n');
      end

    end

    function installDeps()
      import affineDetectors.*;
      if sfop.isInstalled(),
        fprintf('Detector SFOP is already installed\n');
        return
      end
      fprintf('Downloading SFOP to: %s ...\n',sfop.rootInstallDir);

      cwd = fileparts(mfilename('fullpath'));
      installDir = fullfile(cwd,sfop.rootInstallDir);

      try
        untar(sfop.softwareUrl,installDir);
      catch err
        warning('Error downloading from: %s\n',sfop.softwareUrl);
        fprintf('Following error was reported while untarring: %s\n',...
                 err.message);
      end

      fprintf('SFOP download and install complete\n\n');
    end

    function response = isInstalled()
      import affineDetectors.*;
      cwd = fileparts(mfilename('fullpath'));
      installDir = fullfile(cwd,sfop.rootInstallDir);
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
