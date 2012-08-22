classdef Installer < helpers.GenericInstaller
  
  methods (Static)
    function srclist = getMexSources()
      path = fullfile('+helpers','');
      srclist = {fullfile(path,'+CalcMD5','CalcMD5.c')};
    end
    
    function deps = getDependencies()
      deps = {helpers.VlFeatInstaller()};
    end
  end
  
end

