classdef Installer < helpers.GenericInstaller
  
  methods (Static)
    function srclist = getMexSources()
      path = fullfile('+benchmarks','+helpers','');
      srclist = {fullfile(path,'greedyBipartiteMatching.c'),...
        fullfile(path,'mexComputeEllipseOverlap.cpp')};
    end
    
  end
  
end

