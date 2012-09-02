function archivePath = downloadFile( url, distDir )
%DOWNLOADFILE Download a file
%   FILEPATH = DOWNLOADFILE(URL, DISTDIR) Download a file defined by URL
%     to a directory DISTDIR. FILEPATH is a path if file is succesfully 
%     downloaded or empty string otherwise.
%     If the DISTDIR does not exist, it is created.
%     Current implementation uses `wget` which should be available in 
%     system path.

wgetCommand = 'wget %s -O %s'; % Command for downloading archives

[address filename ext] = fileparts(url);
vl_xmkdir(distDir);
archivePath = fullfile(pwd,distDir,[filename ext]);
wgetC = sprintf(wgetCommand,url,archivePath);

status = system(wgetC,'-echo');
if status ~= 0 
  warning('Error downloading, exit status %d',status);
  archivePath = '';
end

end

