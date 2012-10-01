function touch( fileName )
% TOUCH Change the file access and modification date to current time
%   touch(fileName) Changes the fileName modification and access time to
%   the current time. Behaves the same as linux utility touch although
%   does not create file if does not exist.

% Authors: Karel Lenc

% AUTORIGHTS

system(['perl -we "utime undef, undef, ''' fileName '''"']);

end

