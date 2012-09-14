classdef Sfop < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% SFOP class to wrap around the SFOP detector implementation
%   SFOP('Option','OptionValue',...) create new object of the wrapper
%   around the implementation of SFOP available at:
%   http://www.ipb.uni-bonn.de/index.php?id=220#software
%   Options passed to the constructor are passed to SFOP.
%
%   The options are documented in the SFOP code, which you can see at
%   +affineDetectors/thirdParty/sfop/sfop-0.9/matlab/sfopParams.m
%   (the above file only exists once you have installed all the third party
%   software using install command)

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % Properties below correspond to the binary downloaded
    % from vgg
    sfop_varargin % See SFOP documentation for parameters, in the file:
                  % sfop-0.9/matlab/sfopParams.m
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','sfop','');
    dir = fullfile(localFeatures.Sfop.rootInstallDir,'sfop-1.0','');
    matDir = fullfile(pwd,localFeatures.Sfop.dir,'matlab','');
    binPath = fullfile(pwd,localFeatures.Sfop.dir,'src','sfop');
    softwareUrl = 'http://www.ipb.uni-bonn.de/fileadmin/research/media/sfop/sfop-1.0.tar.gz';
    configCmd = './configure --disable-gpu --disable-doxygen CC=%s CXX=%s';
    makeCmd = 'make';
  end
  
  methods
    function obj = Sfop(varargin)
      import localFeatures.*;
      obj.name = 'SFOP';
      obj.detectorName = obj.name;
      obj.sfop_varargin = obj.configureLogger(obj.name,varargin);
      if ~obj.isInstalled(),
        obj.warn('Not installed');
        obj.install();
      end
    end

    function frames = extractFeatures(obj, imagePath)
      import helpers.*;

      frames = obj.loadFeatures(imagePath, false);
      if numel(frames) > 0; return; end;
      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
      end
      tmpName = tempname;
      outFile = [tmpName '.points'];

      detImagePath = fullfile(pwd,imagePath);
      curDir = pwd;
      cd(obj.matDir);
      try
        sfop(detImagePath,outFile,obj.sfop_varargin{:});
      catch err
        cd(curDir);
        throw(err);
      end
      cd(curDir);

      % Above output uses the same output format as vggMser
      frames = localFeatures.helpers.readFramesFile(outFile);
      % Discs are exported as ellipses, convert to discs.
      frames = [frames(1:2,:) ; sqrt(frames(3,:))];
      delete(outFile);
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function signature = getSignature(obj)
      import helpers.*;
      signature = helpers.fileSignature(obj.binPath);
    end
  end

  methods (Static)
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {Sfop.softwareUrl};
      dstPaths = {Sfop.rootInstallDir};
    end

    function compile()
      import localFeatures.*;
      cxx = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      cc = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      
      curDir = pwd;
      cd(Sfop.dir);
      try
        system(sprintf(Sfop.configCmd,cc,cxx),'-echo');
        system(Sfop.makeCmd, '-echo');
        cd(curDir);
      catch err
        cd(curDir);
        throw(err);
      end
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
