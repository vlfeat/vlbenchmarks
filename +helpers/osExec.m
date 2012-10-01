function [ ret res ] = osExec( varargin )
% OS_EXEC Run a command with system library paths
%   [STATUS RESULT] = OS_EXEC('command') Run a command. Parameters are the
%   same as for system command.
%   This script sets LD_LIBRARY_PATH environment variable to contain all
%   system paths received from ldconfig cache.
%   This behaviour is supported only on GLNX86 and GLNXA64 systems, 
%
%  See also: system

% Authors: Karel Lenc

% AUTORIGHTS
import helpers.*;

osType = computer;
% For unsupported systems just call system
if strcmp(osType,'PCWIN') || strcmp(osType,'PCWIN64')
  system(varargin{:});
  return;
end

[ret res] = system('ldconfig -p | grep -o "/.*/" | sort | uniq');
if ret ~= 0
  error('Error getting system libraries: %s',res);
end
sysLibPaths=regexp(strtrim(res),'\n','split');

matlabLdLibPath = getenv('LD_LIBRARY_PATH');
ldLibPath = [cell2str(sysLibPaths,':') ':' matlabLdLibPath];

try
  setenv('LD_LIBRARY_PATH',ldLibPath);
  [ret res] = system(varargin{:});
catch err
  % return back the matlab configuration
  setenv('LD_LIBRARY_PATH',matlabLdLibPath);
  throw(err);
end

setenv('LD_LIBRARY_PATH',matlabLdLibPath);

end

