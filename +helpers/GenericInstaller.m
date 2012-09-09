classdef GenericInstaller < handle
% GENERICINSTALLER Helper class to install data and code dependencies
%   GENERICINSTALLER is a helper class implementing several scripts
%   for installation of data and code dependencies. The installation
%   process is divided into four parts, executed in order:
%
%   1. Installation of dependencies::
%      Defined by the return values of the getDependencies() method.
%
%   2. Installation of tarballs (archives)::
%      Defined by the return values of the getTarballsList()
%      method, providing a list of URLs.
%
%   3. Compilation of third party code::
%      Defined by the implementation of the compile() method.
%      This method implements a user-provided script.
%
%   4. MEX files compilation::
%      Defined by the getMexSources() method.
%
%   In order to specify your installations steps, specify this class
%   as a superclass of your own object and reimplement these static
%   methods.
%
%   This class implements the method isInstalled() wthat tests all
%   the dependencies and whether the apropriate folders are present.
%   If you want to test if your software is compiled, reimplement
%   method isInstalled().
%
%   The method install() executes all the installation steps.

% AUTORIGHTS
  properties (Constant)
    unpackedTagFileExt = '.unpacked';
  end

  methods
    function obj=GenericInstaller()
      if obj.isInstalled()
        obj.setup();
      end
    end

    function res = isInstalled(obj)
    % ISINSTALLED Test whether all the specified data are installed
      res = obj.dependenciesInstalled() ...
        && obj.tarballsInstalled() ...
        && obj.isCompiled() ...
        && obj.mexFilesCompiled();
    end

    function install(obj)
    % INSTALL Install class dependencies
    %   Install unmet dependencies, downloads and unpack tarballs,
    %   run the compile script based on isCompiled() return value and
    %   compiles the mex files.
      obj.installDependencies();
      obj.installTarballs();
      obj.compile();
      obj.compileMexFiles();
      obj.setup();
    end

    function res = dependenciesInstalled(obj)
    % DEPENDENCIESINSTALED Test whether all class dependencies
    %   are installed
      deps = obj.getDependencies();
      res = true;
      for dep = deps
        depIsInstalled = dep{:}.isInstalled();
        if ~depIsInstalled
          res = false;
          return;
        end
      end
    end

    function res = mexFilesCompiled(obj)
    % MEXFILESCOMPILED Test whether all mex files are compiled
      mexSources = obj.getMexSources();
      for source=mexSources
        [srcPath srcFilename] = fileparts(source{:});
        mexFile = fullfile(srcPath,[srcFilename '.' mexext]);
        if ~exist(mexFile,'file')
          res = false;
          return
        end
      end
      res = true;
    end

    function res = tarballsInstalled(obj)
    % TARBALLSINSTALLED Test whether all tarballs are downloaded.
    %   Tests if the folder where the tarball should be unpacked
    %   exist.
      [urls dstPaths] = obj.getTarballsList();
      for i = 1:numel(dstPaths)
        [address filename ext] = fileparts(urls{i});
        % Create dummy file to tag that archive has been unpacked
        unpackTagFile = fullfile(dstPaths{i},['.',filename,ext,...
          obj.unpackedTagFileExt]);
        if ~exist(unpackTagFile,'file')
          res = false;
          return
        end
      end
      res = true;
    end

    function compileMexFiles(obj)
    % COMPILEMEXFILES Compile specified mex file
    %   List of mex files is specified by getMexSources method
    %   implementation.
      if obj.mexFilesCompiled()
        return;
      end
      [sources flags] = obj.getMexSources();
      numSources = numel(sources);
      if ~exist('flags','var'), flags = cell(1,numSources); end;
      for i = 1:numSources
        obj.installMex(sources{i},flags{i});
      end
    end

    function installTarballs(obj)
    % INSTALLTARBALLS Download and unpack all tarballs (archives)
    %   List of tarballs and their unpack folder are defined by
    %   getTarballsList() method implementation.
      if obj.tarballsInstalled()
        return;
      end

      [urls dstPaths] = obj.getTarballsList();
      for i = 1:min(numel(urls),numel(dstPaths))
        obj.installTarball(urls{i},dstPaths{i});
      end
    end

    function res = installDependencies(obj)
    % INSTALLDEPENDENCIES Install all dependencies.
    %   List of classes which this class depends on is defined by
    %   return values of method getDependencies().
      if obj.dependenciesInstalled()
        return;
      end

      deps = obj.getDependencies();
      res = true;
      for dep = deps
        dep{:}.install();
      end
    end

  end

  methods (Static)
    function [srclist flags]  = getMexSources()
      % [SRCLIST FLAGS] = GETMEXSOURCES()
      %   Reimplement this method if mex files compilation
      %   is needed. SRCLIST and FLAGS are cell arrays of same
      %   length which specify paths to C/CPP sources and mex
      %   compilation flags respectively.
      srclist = {};
      flags = {};
    end

    function [urls dstPaths] = getTarballsList()
      % [URLS DSTPATHS] = GETTARBALLSLIST()
      %   Reimplement this method if your class need to download and
      %   unpack data. URLS and DSTPATHS are cell arrays of same
      %   length which specify locations of the tarballs and the
      %   unpack folders respectively.
      urls = {};
      dstPaths = {};
    end

    function deps = getDependencies()
      % DEPS = GETDEPENDENCIES()
      %   Reimplement this method if your class depends on different
      %   classes. Returns cell aray of objects.
      deps = {};
    end

    function res = isCompiled()
    % ISCOMPILED() Reimplement this method to specify whether
    %   compilation (or another script) is neede.
      res = true;
    end

    function compile()
    % COMPILE() Reimplement this method if your class need to compile
    %   or perform another actions during installation process.
    end

    function setup()
     % SETUP() Reimplement this method if your class need to adjust Matlab
     %   environment before it can be used.
    end

    function installMex(mexFile, flags)
      if ~exist('flags','var'), flags = ''; end;
      curDir = pwd;
      [mexDir mexFile mexExt] = fileparts(mexFile);
      mexCmd = sprintf('mex %s %s -O', [mexFile mexExt], flags);
      fprintf('Compiling: %s\n',mexCmd);
      cd(mexDir);
      try
        eval(mexCmd);
      catch err
        cd(curDir);
        throw(err);
      end
      cd(curDir);
    end

    function installTarball(url,distDir)
      import helpers.*;
      [address filename ext] = fileparts(url);
      unpackTagFile = fullfile(distDir,['.',filename,ext,...
        GenericInstaller.unpackedTagFileExt]);
      % Check whether the file is not already downloaded
      if exist(unpackTagFile,'file')
        fprintf('Archive %s already unpacked.\n',[filename,ext]);
        return;
      end
      fprintf('Downloading and unpacking %s.\n',url);
      helpers.unpack(url, distDir);
      
      % Create dummy file to tag that archive has been unpacked
      f = fopen(unpackTagFile,'w');
      fclose(f);
    end

  end

end

