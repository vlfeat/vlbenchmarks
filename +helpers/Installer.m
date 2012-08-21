classdef Installer
  
  methods
    function res = isInstalled(obj)
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
    
    function installDeps(obj)
      if obj.isInstalled()
        return;
      end
      
      mexSources = obj.getMexSources();
      for source=mexSources
        obj.installMex(source{:});
      end
    end
    
  end
  
  methods (Static)
    function srclist = getMexSources()
      path = fullfile('+helpers','');
      srclist = {fullfile(path,'+CalcMD5','CalcMD5.c')};
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
    
  end
  
end

