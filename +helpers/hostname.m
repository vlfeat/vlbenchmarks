function hname = hostname()
% HOSTNAME Get hostname
%   NAME = HOSTNAME() returns hostname NAME. On PCWIN returns the value of
%   COMPUTERNAME environment variable or calls 'hostname' command on other
%   systems.

% Authors: Karel Lenc

% AUTORIGHTS
switch computer
  case {'PCWIN','PCWIN64'}
    hname = getenv('COMPUTERNAME');
  otherwise
    [ret msg] = system('hostname');
    if ret
      error('Unable to get hostname:\n%s\n',msg);
    else
      hname = strtrim(msg);
    end
end