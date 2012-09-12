% SFOP class to wrap around the SFOP detector implementation
%
%   obj = localFeatures.sfop('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   obj class implements the genericDetector interface and wraps around
%   the implementation of SFOP available at:
%   http://www.ipb.uni-bonn.de/index.php?id=220#software
%
%   The options are documented in the SFOP code, which you can see at
%   +affineDetectors/thirdParty/sfop/sfop-0.9/matlab/sfopParams.m
%   (the above file only exists once you have installed all the third party
%   software using install command)

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
    dir = fullfile(localFeatures.sfop.rootInstallDir,'sfop-1.0','');
    matDir = fullfile(pwd,localFeatures.sfop.dir,'matlab','');
    binPath = fullfile(pwd,localFeatures.sfop.dir,'src','sfop');
    softwareUrl = 'http://www.ipb.uni-bonn.de/fileadmin/research/media/sfop/sfop-1.0.tar.gz';
    configCmd = './configure --disable-gpu --disable-doxygen CC=%s CXX=%s';
    makeCmd = 'make';
  end
  
  methods
    % The constructor is used to set the options for vggAffine
    function obj = sfop(varargin)
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
    
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      obj.error('Descriptor calculation of provided frames not supported');
    end
    
    function signature = getSignature(obj)
      import helpers.*;
      signature = helpers.fileSignature(obj.binPath);
    end
  end

  methods (Static)
    
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {sfop.softwareUrl};
      dstPaths = {sfop.rootInstallDir};
    end
    
    function compile()
      import localFeatures.*;
      cxx = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      cc = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      
      curDir = pwd;
      cd(sfop.dir);
      try
        system(sprintf(sfop.configCmd,cc,cxx),'-echo');
        system(sfop.makeCmd, '-echo');
        cd(curDir);
      catch err
        cd(curDir);
        throw(err);
      end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
