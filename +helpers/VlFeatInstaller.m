classdef VlFeatInstaller < helpers.GenericInstaller
% VLFEATINSTALLER Downloads and installs VLFeat library
%    See or adjust constant class arguments for details about the 
%    library version or location.
%
%    The MEXFLAGS constant property can be used for your mexFiles
%    which depend and link to the VLFeat library.
    
  properties (Constant)
    installVersion = '0.9.14';
    installDir = fullfile('data','software','vlfeat');
    name = ['vlfeat-' helpers.VlFeatInstaller.installVersion];
    dir = fullfile(pwd,helpers.VlFeatInstaller.installDir,...
      helpers.VlFeatInstaller.name,'');
    url = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz',...
      helpers.VlFeatInstaller.installVersion);
    mexDir = fullfile(helpers.VlFeatInstaller.dir,'toolbox','mex',mexext);
    makeCmd = 'make';
    
    % Flags for mex files which link to VLFeat
    MEXFLAGS = sprintf('LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lvl -I%s',...
      helpers.VlFeatInstaller.mexDir,helpers.VlFeatInstaller.mexDir,...
      helpers.VlFeatInstaller.dir);
  end
  
  methods (Static)    
    function [urls dstPaths] = getTarballsList()
      import helpers.*;
      urls = {VlFeatInstaller.url};
      dstPaths = {VlFeatInstaller.installDir};
    end
    
    function compile()
      import helpers.*;
      if VlFeatInstaller.isCompiled()
        return;
      end
      
      fprintf('Compiling vlfeat\n');
      
      prevDir = pwd;
      cd(VlFeatInstaller.dir);

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

