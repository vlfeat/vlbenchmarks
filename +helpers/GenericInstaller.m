classdef GenericInstaller < handle
  properties (Constant)
    wgetCommand = 'wget %s';
    unbzipCommand = 'tar xvjf %s'
  end
  
  methods
    function res = isInstalled(obj)
      res = obj.dependenciesInstalled() ...
        && obj.tarballsInstalled() ...
        && obj.isCompiled() ...
        && obj.mexFilesCompiled();
    end
    
    function installDeps(obj)
      obj.installDependencies();
      obj.installTarballs();
      obj.compile();
      obj.compileMexFiles();
    end
    
    function res = dependenciesInstalled(obj)
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
      [urls dstPaths] = obj.getTarballsList();
      for path = dstPaths
        if ~exist(path{:},'dir')
          res = false;
          return
        end
      end
      res = true;
    end
    
    function compileMexFiles(obj)
      if obj.mexFilesCompiled()
        return;
      end
      
      mexSources = obj.getMexSources();
      for source=mexSources
        obj.installMex(source{:});
      end
    end
    
    function installTarballs(obj)
      if obj.tarballsInstalled()
        return;
      end
      
      [urls dstPaths] = obj.getTarballsList();
      for i = 1:min(numel(urls),numel(dstPaths))
        obj.installTarball(urls{i},dstPaths{i});
      end
    end
    
    function res = installDependencies(obj)
      if obj.dependenciesInstalled()
        return;
      end
      
      deps = obj.getDependencies();
      res = true;
      for dep = deps
        dep{:}.installDeps();
      end
    end
      
  end
  
  methods (Static)
    function srclist = getMexSources()
      srclist = {};
    end
    
    function [urls dstPaths compileCmds] = getTarballsList()
      urls = {};
      dstPaths = {};
      compileCmds = {};
    end
    
    function deps = getDependencies()
      deps = {};
    end
    
    function res = isCompiled()
      res = true;
    end
    
    function compile()
    end
    
    function installMex(mexFile)
      curDir = pwd;
      [mexDir mexFile mexExt] = fileparts(mexFile);
      cd(mexDir);
      mexCmd = sprintf('mex -O %s',[mexFile mexExt]);
      fprintf('Compiling: %s\n',mexCmd);
      eval(mexCmd);
      cd(curDir);
    end
    
    function installTarball(url,distDir,compileCmd)
      [address filename ext] = fileparts(url);
      fprintf('Downloading and unpacking %s.\n',url);
      try
        switch ext
          case {'.tar','.gz','.tgz'}
            untar(url,distDir);
          case '.zip'
            unzip(url,distDir);
          case '.bz2'
            
          otherwise
            error(['Unknown archive extension ' ext]);
        end 
      catch err
        warning('Error downloading from: %s\n',url);
        throw(err);
      end
    end
    
  end
  
end

