classdef Sfop < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% localFeatures.Sfop class to wrap around the SFOP detector implementation
%   localFeatures.Sfop('Option','OptionValue',...) create new object of the
%   wrapper around the implementation of SFOP available at: 
%   http://www.ipb.uni-bonn.de/index.php?id=220#software 
%   Options passed to the constructor are passed to SFOP function.
%
%   The options are documented in the SFOP code, which you can see at
%   +affineDetectors/thirdParty/sfop/sfop-0.9/matlab/sfopParams.m
%   (the above file only exists once you have installed all the third party
%   software using install command)

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    % See SFOP documentation for parameters, in the file:
    % sfop-0.9/matlab/sfopParams.m
    SfopArguments 
  end

  properties (Constant, Hidden)
    RootInstallDir = fullfile('data','software','sfop','');
    DataDir = fullfile(localFeatures.Sfop.RootInstallDir,'sfop-1.0','');
    MatDir = fullfile(pwd,localFeatures.Sfop.DataDir,'matlab','');
    BinPath = fullfile(pwd,localFeatures.Sfop.DataDir,'src','sfop');
    SoftwareUrl = 'http://www.ipb.uni-bonn.de/fileadmin/research/media/sfop/sfop-1.0.tar.gz';
    ConfigCmd = './configure --disable-gpu --disable-doxygen CC=%s CXX=%s';
    MakeCmd = 'make';
  end
  
  methods
    function obj = Sfop(varargin)
      import localFeatures.*;
      obj.Name = 'SFOP';
      varargin = obj.checkInstall(varargin);
      obj.SfopArguments = obj.configureLogger(obj.Name,varargin);
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
      cd(obj.MatDir);
      try
        sfop(detImagePath,outFile,obj.SfopArguments{:});
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
      obj.debug('%d Frames from image %s computed in %gs',...
        size(frames,2), getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, []);
    end

    function signature = getSignature(obj)
      import helpers.*;
      signature = helpers.fileSignature(obj.BinPath);
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {Sfop.SoftwareUrl};
      dstPaths = {Sfop.RootInstallDir};
    end

    function compile(obj)
      import localFeatures.*;
      cxx = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      cc = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
      
      curDir = pwd;
      cd(Sfop.DataDir);
      try
        system(sprintf(Sfop.ConfigCmd,cc,cxx),'-echo');
        system(Sfop.MakeCmd, '-echo');
        cd(curDir);
      catch err
        cd(curDir);
        throw(err);
      end
    end
  end
end
