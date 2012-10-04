classdef VlFeatInstaller < helpers.GenericInstaller
% helpers.VlFeatInstaller Downloads and installs the VLFeat library
%   helpers.VlFeatInstaller('MinVersion') Constructs a VlFeatInstaller
%   object and checks the minimal version 'MinVersion'. If this version
%   is not available, fails with error.
%
%   To set what version should be installed edit the constant properties
%   VlFeatInstaller.Version.
%
% See also: helpers.GenericInstaller

% Author: Karel Lenc

% AUTORIGHTS
  properties (Constant)
    Version = '0.9.16';
    RootDir = fullfile('data','software','vlfeat');
    Name = ['vlfeat-' helpers.VlFeatInstaller.Version];
    InstallDir = fullfile(helpers.VlFeatInstaller.RootDir,...
      helpers.VlFeatInstaller.Name,'');
    Url = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz', ...
      helpers.VlFeatInstaller.Version);
    MexDir = fullfile(helpers.VlFeatInstaller.InstallDir,'toolbox','mex',mexext);
    MakeCmd = 'make';
  end

  methods
    function obj = VlFeatInstaller(minVersion)
      if exist('minVersion','var')
        versionParts = regexp(obj.Version,'\.','split');
        minVersionParts = regexp(minVersion,'\.','split');
        numVersion =  str2double(strcat(versionParts{:}));
        numMinVersion = str2double(strcat(minVersionParts{:}));
        if numVersion < numMinVersion
          error('VlFeat version >= %s is not available. Change the version in file %s.',...
            minVersion,mfilename);
        end
      end
      if obj.isInstalled()
        obj.setup();
      end
    end

    function setup(obj)
      % setup Set up the Matlab path to contain VLFeat paths
      if(~exist('vl_demo','file')),
        fprintf('Adding VLFeat to path.\n');
        vlFeatDir = helpers.VlFeatInstaller.InstallDir;
        if(exist(vlFeatDir,'dir'))
          run(fullfile(vlFeatDir,'toolbox','vl_setup.m'));
        else
          error('VLFeat not found, cannot setup properly.\n');
        end
      end
    end

    function unload(obj)
      clear mex;
      fprintf('Removing VLFeat from path.\n');
      obj.rmPaths(obj.RootDir);
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import helpers.*;
      urls = {VlFeatInstaller.Url};
      dstPaths = {VlFeatInstaller.RootDir};
    end

    function compile(obj)
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      fprintf('Compiling VLFeat\n');

      prevDir = pwd;
      cd(VlFeatInstaller.InstallDir);
      status = system(VlFeatInstaller.MakeCmd);
      cd(prevDir);

      if status ~= 0
        error('VLFeat compilation was not succesfull.\n');
      end
	    obj.setup();
    end

    function res = isCompiled(obj)
      import helpers.*;
      res = exist(VlFeatInstaller.MexDir,'dir');
    end

    function deps = getDependencies(obj)
      deps = {helpers.Installer};
    end
  end

  methods (Static)
    function mexflags = getMexFlags()
    % getMexFlags Get flags for compilation of mex files
    %   MEX_FLAGS = getMexFlags() Returns mex flags needed for compilation
    %   of mex files which link to VlFeat library.
      import helpers.*;
      switch computer()
        case {'GLNX86','GLNXA64'}
        mexflags = sprintf(...
          'LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lvl -I%s',...
          VlFeatInstaller.MexDir, VlFeatInstaller.MexDir,...
          VlFeatInstaller.InstallDir);
        otherwise
          warning('Architecture not supported yet.');
      end
    end

    function dllPath = getDynamicLibraryPath()
      % getDynamicLibraryPath Get path of VLFeat library
      %   DLL_PATH = getDynamicLibraryPath() returns DLL_PATH path to
      %   VLFeat dynamic library based on the platform.
      import helpers.*;
      switch computer
        case {'GLNXA64','GLNX86'}
          vlDllFileName = 'libvl.so';
        case {'PCWIN','PCWIN64'}
          vlDllFileName = 'vl.dll';
        case {'MACI64'}
          vlDllFileName = 'libvl.dylib';
        otherwise
          error('Unknown architecture');
      end
      dllPath = fullfile(VlFeatInstaller.MexDir,vlDllFileName);
    end

    function signature = getBinSignature(vlFunctionName)
      % getBinSignature Get a signature of VlFeat command binaries.
      %   SIGNATURE = getBinSignature(VL_FUNCTION_NAME) Returns signature
      %   mex file used for VL_FUNCTION_NAME and the VlFeat dynamic
      %   library.
      import helpers.*;
      dllPath = VlFeatInstaller.getDynamicLibraryPath();
      mexPath = fullfile(VlFeatInstaller.MexDir,...
        [vlFunctionName '.' mexext]);
      if ~exist(mexPath,'file')
        error('Unknown function, mex %s does not exist.',mexPath);
      end
      signature = [fileSignature(dllPath),fileSignature(mexPath)];
    end
  end
end
