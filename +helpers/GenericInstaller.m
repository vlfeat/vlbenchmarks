classdef GenericInstaller < handle
% helpers.GenericInstaller Helper class to install data and code dependencies
%   helpers.GenericInstaller is a helper class implementing several scripts
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

% Author: Karel Lenc

% AUTORIGHTS
  properties (Constant, Hidden)
    unpackedTagFileExt = '.unpacked';
  end

  methods (Access = public)
    function res = isInstalled(obj)
    % isInstalled Test whether all the specified data are installed
    %   RES = obj.isInstalled() Returns RES=true when the class has
    %   got installed all needed resources.
      res = obj.dependenciesInstalled() ...
        && obj.tarballsInstalled() ...
        && obj.isCompiled() ...
        && obj.mexFilesCompiled();
    end

    function install(obj)
    % install Install class dependencies 
    %   obj.install() Installs unmet dependencies, downloads and
    %   unpack tarballs, run the compile script based on isCompiled()
    %   return value and compiles the mex files.
    %
    % See also: GenericInstaller.clean
      obj.installDependencies();
      obj.installTarballs();
      obj.compile();
      obj.compileMexFiles();
	    obj.setup();
    end

    function clean(obj)
    % clean Clean all installed resources
    %   clean() Cleans all allocated resources. Deletes compiled mex
    %   files, cleans compiled files (calling cleanCompiled()) and
    %   deletes downloaded tarballs.
    %
    % See also: GenericInstaller.install
      if ~obj.isInstalled(), return; end;
      obj.unload();
      srclist = obj.getMexSources();
      % Clean the compiled mex files
      for mexSrc = srclist
        [srcPath srcFilename] = fileparts(mexSrc{:});
        mexFile = fullfile(srcPath,[srcFilename '.' mexext]);
        if exist(mexFile,'file')
          fprintf('Deleting mex: %s.\n',mexFile);
          delete(mexFile);
        end
      end
      % Clean compiled resources
      obj.cleanCompiled();
      % Clean downloaded archives
      [urls dstPaths] = obj.getTarballsList();
      for path = dstPaths
        if exist(path{:},'dir')
          fprintf('Removing directory: %s.\n',path{:});
          rmdir(path{:},'s')
        end
      end
    end

    function setup(obj)
    % setup Setup the class environment.
    %   obj.setup() Implementation of this method should set up the
    %   environment needed by the class object (e.g. path etc.).
    %
    % See also: GenericInstaller.unload
    end

    function unload(obj)
    % unload Unload the class environment.
    %   obj.unload() Implementation of this method should unload the
    %   environment needed by the class object (e.g. path etc.),
    %   opposite to setup.
    %
    % See also: GenericInstaller.setup
    end
  end

  methods (Access=protected, Hidden)
    function res = dependenciesInstalled(obj)
    % dependenciesInstalled Test whether all class dependencies
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
    % mexFilesCompiled Test whether all mex files are compiled
      mexSources = obj.getMexSources();
      for source=mexSources
        if ~obj.mexFileCompiled(source{:});
          res = false;
          return
        end
      end
      res = true;
    end

    function res = tarballsInstalled(obj)
    % tarballsInstalled Test whether all tarballs are downloaded.
    %   Tests whether in all dest. directories exist a dummy file 
    %   <dst_dir>/.<archive_name>.unpacked
      import helpers.*;
      [urls dstPaths] = obj.getTarballsList();
      for i = 1:numel(dstPaths)
        if ~obj.tarballInstalled(urls{i}, dstPaths{i});
          res = false;
          return
        end
      end
      res = true;
    end

    function compileMexFiles(obj)
    % compileMexFiles Compile specified mex file
    %   List of mex files is specified by getMexSources method
    %   implementation.
      [sources flags] = obj.getMexSources();
      numSources = numel(sources);
      if ~exist('flags','var'), flags = cell(1,numSources); end;
      for i = 1:numSources
        if ~obj.mexFileCompiled(sources{i})
          obj.compileMex(sources{i},flags{i});
        end
      end
    end

    function installTarballs(obj)
    % installTarballs Download and unpack all tarballs (archives)
    %   List of tarballs and their unpack folder are defined by
    %   getTarballsList() method implementation. Only non-extracted
    %   tarballs (i.e. without tag file) are downloaded and extracted.
      if obj.tarballsInstalled()
        return;
      end
      [urls dstPaths] = obj.getTarballsList();
      for i = 1:min(numel(urls),numel(dstPaths))
        if ~obj.tarballInstalled(urls{i}, dstPaths{i});
          obj.installTarball(urls{i},dstPaths{i});
        end
      end
    end

    function res = installDependencies(obj)
    % installDependencies Install all dependencies.
    %   List of classes which this class depends on is defined by
    %   return values of method getDependencies().
      deps = obj.getDependencies();
      res = true;
      for dep = deps
        if ~dep{:}.isInstalled()
          dep{:}.install();
        end
      end
    end

    function varargin = checkInstall(obj, varargin)
    % checkInstall Check whether object is installed.
    %   obj.checkInstall('AutoInstall', false) Do not install if not
    %   installed.
      import helpers.*;
      opts.autoInstall = true;
      [opts varargin] = vl_argparse(opts, varargin{:});
      if opts.autoInstall && ~obj.isInstalled()
        obj.install();
      end
    end

    function [srclist flags]  = getMexSources(obj)
      % [SRCLIST FLAGS] = obj.getMexSources()
      %   Reimplement this method if mex files compilation
      %   is needed. SRCLIST and FLAGS are cell arrays of same
      %   length which specify paths to C/CPP sources and mex
      %   compilation flags respectively.
      srclist = {};
      flags = {};
    end

    function [urls dstPaths] = getTarballsList(obj)
      % [URLS DSTPATHS] = obj.getTarballsList()
      %   Reimplement this method if your class need to download and
      %   unpack data. URLS and DSTPATHS are cell arrays of same
      %   length which specify locations of the tarballs and the
      %   unpack folders respectively.
      urls = {};
      dstPaths = {};
    end

    function deps = getDependencies(obj)
      % DEPS = obj.getDependencies()
      %   Reimplement this method if your class depends on different
      %   classes. Returns cell aray of objects.
      deps = {};
    end

    function res = isCompiled(obj)
    % obj.isCompiled() Reimplement this method to specify whether
    %   compilation (or another script) is neede.
      res = true;
    end

    function compile(obj)
    % obj.compile() Reimplement this method if your class need to compile
    %   or perform another actions during installation process.
    end

    function cleanCompiled(obj)
    % obj.cleanCompiled() Reimplement this function if your compile function
    % creates some files/resources out of the tarball destination 
    % directories which are deleted automatically during the clean() call.
    end
  end

  methods (Static, Hidden)
    function res = mexFileCompiled(mexFile)
      % mexFileCompiled Test whether a mex file is compiled
      [srcPath srcFilename] = fileparts(mexFile);
      mexFile = fullfile(srcPath,[srcFilename '.' mexext]);
      res = exist(mexFile,'file');
    end

    function compileMex(mexFile, flags)
      % compileMex Compile a C/C++ source with 'mex' command
      %   compileMex(MEX_SRC_FILE, FLAGS) Compiles MEX_SRC_FILE with mex
      %   command including FLAGS as its parameters.
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

    function res = tarballInstalled(url, distDir)
      % tarballInstalled Check whether a tarball is successfully unpacked
      import helpers.*;
      unpackTagFile = GenericInstaller.getUnapckedTagFile(url, distDir);
      res = exist(unpackTagFile,'file');
    end

    function installTarball(url,distDir)
      % installTarball Unpack a tarball
      import helpers.*;
      fprintf('Downloading and unpacking %s.\n',url);
      unpackTagFile = GenericInstaller.getUnapckedTagFile(url, distDir);
      try
        helpers.unpack(url, distDir);
      catch err
        fprintf('Error downloading and unpacking archive.\n');
        fprintf('If you want to skip this step, download archive:\n\n');
        fprintf('%s\n\nAnd unpack it to a directory:\n\n%s\n\n',url,fullfile(pwd,distDir));
        fprintf('And create an empty file:\n\n%s\n\n',fullfile(pwd,unpackTagFile));
        fprintf('Which tags that the archive has been succesfully unpacked.\n');
        throw(err);
      end
      % Create dummy file to tag that archive has been unpacked
      f = fopen(unpackTagFile,'w');
      fclose(f);
    end

    function unpackTagFile = getUnapckedTagFile(url, distDir)
      % FILENAME = getUnapckedTagFile(URL, DISTDIR) Get path to a tag file
      %   FILENAME which signal that an tarball URL has been unpacked to a
      %   folder DISTDIR
      import helpers.*;
      [address filename ext] = fileparts(url);
      unpackTagFile = fullfile(distDir,['.',filename,ext,...
        GenericInstaller.unpackedTagFileExt]);
    end

    function rmPaths(pattern)
      % RMPATHS Remove directories from Matlab path
      %   RMPATHS(PATTERN) Remove all directories which match pattern from
      %   Matlab path.
      paths = regexp(path(),':','split');
      isMatchingPath = ~cellfun(@isempty,strfind(paths,pattern));
      matchingPaths = paths(isMatchingPath);
      if ~isempty(matchingPaths)
        rmpath(matchingPaths{:});
      end
    end
  end

end

