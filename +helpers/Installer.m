classdef Installer < helpers.GenericInstaller
% helpersInstaller Installs dependencies and data for the helpers.
%   Compiles CalcMD5 function which is needed for caching.

% Author: Karel Lenc

% AUTORIGHTS
  methods (Access=protected)
    function [srclist flags] = getMexSources(obj)
      path = fullfile('+helpers','');
      srclist = {fullfile(path,'+CalcMD5','CalcMD5.c')};
      flags = {''};
    end
  end
end
