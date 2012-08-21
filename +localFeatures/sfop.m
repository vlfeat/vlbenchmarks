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

classdef sfop < localFeatures.genericLocalFeatureExtractor & ...
    helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
    % Properties below correspond to the binary downloaded
    % from vgg
    sfop_varargin % See SFOP documentation for parameters, in the file:
                  % sfop-0.9/matlab/sfopParams.m
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','sfop','');
    softwareUrl = 'http://www.ipb.uni-bonn.de/fileadmin/research/media/sfop/sfop-0.9.tar.gz';
  end
  
  methods
    % The constructor is used to set the options for vggAffine
    function obj = sfop(varargin)
      import affineDetectors.*;
      if ~obj.isInstalled(),
        obj.installDeps();
      end

      obj.sfop_varargin = obj.configureLogger(obj.detectorName,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      if ~obj.isOk, frames = zeros(5,0); return; end

      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',getFileName(imagePath));
      end

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
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
    end
    
    function signature = getSignature(obj)
      import helpers.*;
    end
  end

  methods (Static)
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {sfop.softwareUrl};
      dstPaths = {sfop.rootInstallDir};
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
