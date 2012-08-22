function unbzip( url, distDir )

wgetCommand = 'wget %s -O %s'; % Command for downloading archives
unbzipCommand = 'tar xvjf %s --directory %s';

[address filename ext] = fileparts(url);

% Download the file
dataDir = fullfile('data');
archivePath = fullfile(dataDir,[filename ext]);
wgetC = sprintf(wgetCommand,url,archivePath);

status = system(wgetC,'-echo');
if status ~= 0 
  error('Error downloading, exit status %d',status); 
end

% Unpack the file
vl_xmkdir(distDir);
unpackC = sprintf(unbzipCommand,archivePath,distDir);

status = system(unpackC,'-echo');
if status ~= 0, error('Error unpacking %s',archivePath); end

% Clean the mess
delete(archivePath);

end

