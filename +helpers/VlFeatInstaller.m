classdef VlFeatInstaller < helpers.GenericInstaller
    
  properties (Constant)
    installVersion = '0.9.14';
    installDir = fullfile('data','software');
    url = 'http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz';
  end
  
  methods (Static)    
    function [urls dstPaths] = getTarballsList()
      import helpers.*;
      urlPattern = VlFeatInstaller.url;
      softwareUrl = sprintf(urlPattern,VlFeatInstaller.installVersion);
      vlFeatName = fullfile(['vlfeat-' VlFeatInstaller.installVersion],'');
      vlFeatDir = fullfile(VlFeatInstaller.installDir,vlFeatName,'');
      
      urls = {softwareUrl};
      dstPaths = {vlFeatDir};
    end
    
    function compile()
      import helpers.*;
      if VlFeatInstaller.isCompiled()
        return;
      end
      
      fprintf('Compiling vlfeat\n');
      
      vlFeatName = ['vlfeat-' VlFeatInstaller.installVersion];
      vlFeatDir = fullfile(VlFeatInstaller.installDir,vlFeatName,'');
      
      prevDir = pwd;
      cd(vlFeatDir);
      % Handle directory structure inside the archive
      movefile([vlFeatName,filesep,'*'],'.');

      status = system('make');
      if status ~= 0
        error('VLFeat compilation was not succesfull.\n');
      end
      
      cd(prevDir);
    end
    
    function res = isCompiled()
      import helpers.*;
      vlFeatName = ['vlfeat-' VlFeatInstaller.installVersion];
      vlFeatDir = fullfile(VlFeatInstaller.installDir,vlFeatName,'');
      mexDir = fullfile(vlFeatDir,'toolbox','mex',mexext);
      
      res = exist(mexDir,'dir');
    end
  end
    
end

