classdef Installer < helpers.GenericInstaller
% INSTALLER Installs dependencies and data for the helpers.
%   Compiles CalcMD5 function which is needed for caching.  
  methods (Access=protected)
    function [srclist flags] = getMexSources(obj)
      path = fullfile('+helpers','');
      srclist = {fullfile(path,'+CalcMD5','CalcMD5.c')};
      flags = {''};
    end
  end
end