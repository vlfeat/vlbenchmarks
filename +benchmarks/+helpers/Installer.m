classdef Installer < helpers.GenericInstaller
% INSTALLER Benchmarks helpers installation.
%
%   Compiles mex files needed for ellipse overlap and matching
%   calculation.
  
  methods (Static)
    function srclist = getMexSources()
      path = fullfile('+benchmarks','+helpers','');
      srclist = {fullfile(path,'greedyBipartiteMatching.c'),...
        fullfile(path,'mexComputeEllipseOverlap.cpp')};
    end
    
  end
  
end

