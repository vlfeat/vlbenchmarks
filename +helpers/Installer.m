classdef Installer < helpers.GenericInstaller
  
  methods (Static)
    function srclist = getMexSources()
      path = fullfile('+helpers','');
      srclist = {fullfile(path,'+CalcMD5','CalcMD5.c')};
    end
    
    function [urls dstPaths compileCmds] = getTarballsList()
      urls = {};
      dstPaths = {};
      compileCmds = {};
    end
    
    function deps = getDependencies()
      deps = {helpers.VlFeatInstaller()};
    end
  end
  
end

