function setFileExecutable( filePath )
% SETFILEEXECUTABLE Set executable flags to a file
%   SETFILEEXECUTABLE(FILE_PATH) Set flags of a file FILE_PATH to make it
%   an executable. Current implementation depends on `chmod` utility.

% Authors: Karel Lenc

% AUTORIGHTS
chmodCmd = sprintf('chmod +x %s',filePath);
system(chmodCmd);

end

