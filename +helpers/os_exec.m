function [ ret res ] = os_exec( varargin )
%OS_EXEC Run a command with system library paths
%  [STATUS RESULT] = OS_EXEC('command') Run a command. Parameters are the
%  same as for system command.
%  This script sets LD_LIBRARY_PATH environment variable to contain paths
%  of system libstc++.so so that C++ binaries can be executed with system
%  command.
%
%  See also: system
import helpers.*;

[ret res] = system('ldconfig -p | grep libstdc++.so | grep -o "/.*/"');
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

