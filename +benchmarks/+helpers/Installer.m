classdef Installer < helpers.GenericInstaller
% INSTALLER Benchmarks helpers installation.
%
%   Compiles mex files needed for ellipse overlap and matching
%   calculation.
  
  methods (Access=protected)
    function [srclist flags] = getMexSources(obj)
      path = fullfile('+benchmarks','+helpers','');
      srclist = {fullfile(path,'greedyBipartiteMatching.c'),...
        fullfile(path,'mexComputeEllipseOverlap.cpp')};
      flags = {'',''};
    end
    
  end
  
end

