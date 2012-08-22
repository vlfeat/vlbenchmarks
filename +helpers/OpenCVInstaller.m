classdef OpenCVInstaller < helpers.GenericInstaller
    
  properties (Constant)
    installVersion = '2.4.2';
    installDir = fullfile('data','software');
    url = 'http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/%s/OpenCV-%s.tar.bz2';
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

