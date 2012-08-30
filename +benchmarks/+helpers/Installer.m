classdef Installer < helpers.GenericInstaller
  
  methods (Static)
    function [srclist flags] = getMexSources()
      path = fullfile('+benchmarks','+helpers','');
      srclist = {fullfile(path,'greedyBipartiteMatching.c'),...
        fullfile(path,'mexComputeEllipseOverlap.cpp')};
      flags = {'',''};
    end
    
  end
  
end

