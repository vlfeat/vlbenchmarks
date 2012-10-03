function archivePath = downloadFile( url, distDir )
% DOWNLOADFILE Download a file
%   FILEPATH = DOWNLOADFILE(URL, DISTDIR) Download a file defined by URL
%   to a directory DISTDIR. FILEPATH is a path if file is succesfully 
%   downloaded or empty string otherwise.
%   If the DISTDIR does not exist, it is created.
%   Current implementation uses `wget` which should be available in 
%   system path.

% Authors: Karel Lenc

% AUTORIGHTS
import helpers.*;

wgetCommand = 'wget %s -O %s'; % Command for downloading archives

[address filename ext] = fileparts(url);
vl_xmkdir(distDir);
archivePath = fullfile(distDir,[filename ext]);
wgetC = sprintf(wgetCommand,url,archivePath);

[status msg] = system(wgetC,'-echo');
if status ~= 0 
  warning('Error downloading: %s',msg);
  archivePath = '';
end

end

