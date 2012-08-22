classdef VlFeatInstaller < helpers.GenericInstaller
    
  properties (Constant)
    installVersion = '0.9.14';
    installDir = fullfile('data','software');
    name = ['vlfeat-' helpers.VlFeatInstaller.installVersion];
    dir = fullfile(pwd,helpers.VlFeatInstaller.installDir,...
      helpers.VlFeatInstaller.name,'');
    url = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz',...
      helpers.VlFeatInstaller.installVersion);
    mexDir = fullfile(helpers.VlFeatInstaller.dir,'toolbox','mex',mexext);
    makeCmd = 'make';
    
    % LDFLAGS for mex compilation
    MEXFLAGS = sprintf('LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lvl -I%s',...
      helpers.VlFeatInstaller.mexDir,helpers.VlFeatInstaller.mexDir,...
      helpers.VlFeatInstaller.dir);
  end
  
  methods (Static)    
    function [urls dstPaths] = getTarballsList()
      import helpers.*;
      urls = {VlFeatInstaller};
      dstPaths = {VlFeatInstaller.dir};
    end
    
    function compile()
      import helpers.*;
      if VlFeatInstaller.isCompiled()
        return;
      end
      
      fprintf('Compiling vlfeat\n');
      
      prevDir = pwd;
      cd(VlFeatInstaller.dir);
      % Handle directory structure inside the archive
      movefile([VlFeatInstaller.dir,filesep,'*'],'.');

      status = system(VlFeatInstaller.makeCmd);
      cd(prevDir);
      
      if status ~= 0
        error('VLFeat compilation was not succesfull.\n');
      end
    end
    
    function res = isCompiled()
      import helpers.*;
      res = exist(VlFeatInstaller.mexDir,'dir');
    end
  end
    
end

