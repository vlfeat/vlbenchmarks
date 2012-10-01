classdef VlFeatInstaller < helpers.GenericInstaller
% helpers.VlFeatInstaller Downloads and installs the VLFeat library
%   helpers.VlFeatInstaller('MinVersion') Constructs a VlFeatInstaller
%   object and checks the minimal version 'MinVersion'. If this version
%   is not available, fails with error.
%
%   To set what version should be installed edit the constant properties
%   VlFeatInstaller.installVersion.
%
% See also: helpers.GenericInstaller

% Author: Karel Lenc

% AUTORIGHTS
  properties (Constant)
    installVersion = '0.9.15';
    installDir = fullfile('data','software','vlfeat');
    name = ['vlfeat-' helpers.VlFeatInstaller.installVersion];
    dir = fullfile(pwd,helpers.VlFeatInstaller.installDir,...
      helpers.VlFeatInstaller.name,'');
    url = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz', ...
      helpers.VlFeatInstaller.installVersion);
    mexDir = fullfile(helpers.VlFeatInstaller.dir,'toolbox','mex',mexext);
    makeCmd = 'make';
  end

  methods
    function obj = VlFeatInstaller(minVersion)
      if exist('minVersion','var')
        numVersion =  str2double(char(regexp(obj.installVersion,'\.','split'))');
        numMinVersion = str2double(char(regexp(minVersion,'\.','split'))');
        if numVersion < numMinVersion
          error('VlFeat version >= %s not available. Change the version in file %s.',...
            numMinVersion,mfilename);
        end
      end
      if obj.isInstalled()
        obj.setup();
      end
    end

    function setup(obj)
      % setup Set up the Matlab path to contain VLFeat paths
      if(~exist('vl_demo','file')),
        vlFeatDir = helpers.VlFeatInstaller.dir;
        if(exist(vlFeatDir,'dir'))
          run(fullfile(vlFeatDir,'toolbox','vl_setup.m'));
        else
          error('VLFeat not found, cannot setup properly.\n');
        end
      end
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import helpers.*;
      urls = {VlFeatInstaller.url};
      dstPaths = {VlFeatInstaller.installDir};
    end

    function compile(obj)
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      fprintf('Compiling VLFeat\n');

      prevDir = pwd;
      cd(VlFeatInstaller.dir);

      status = system(VlFeatInstaller.makeCmd);
      cd(prevDir);

      if status ~= 0
        error('VLFeat compilation was not succesfull.\n');
      end
	    obj.setup();
    end

    function res = isCompiled(obj)
      import helpers.*;
      res = exist(VlFeatInstaller.mexDir,'dir');
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
          VlFeatInstaller.mexDir, VlFeatInstaller.mexDir,...
          VlFeatInstaller.dir);
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
      dllPath = fullfile(VlFeatInstaller.mexDir,vlDllFileName);
    end

    function signature = getBinSignature(vlFunctionName)
      % getBinSignature Get a signature of VlFeat command binaries.
      %   SIGNATURE = getBinSignature(VL_FUNCTION_NAME) Returns signature
      %   mex file used for VL_FUNCTION_NAME and the VlFeat dynamic
      %   library.
      import helpers.*;
      dllPath = VlFeatInstaller.getDynamicLibraryPath();
      mexPath = fullfile(VlFeatInstaller.mexDir,...
        [vlFunctionName '.' mexext]);
      if ~exist(mexPath,'file')
        error('Unknown function, mex %s does not exist.',mexPath);
      end
      signature = [fileSignature(dllPath),fileSignature(mexPath)];
    end
  end
end
