function unbzip( url, distDir )

wgetCommand = 'wget %s -O %s'; % Command for downloading archives
unbzipCommand = 'tar xvjf %s';
unTarGzipCommand = 'tar xvzf %s';
unGzipCommand = 'gunzip %s';
deleteArchive = true;

[address filename ext] = fileparts(url);

switch ext
  case '.gz'
    [d fn ext2] = fileparts(filename);
    if ~strcmp(ext2,'.tar')
      % Handle only gzipped single files
      command = unGzipCommand;
      deleteArchive = false;
    else
      untar(url,distDir);
      return
    end
  case {'.tar','.tgz'}
    untar(url,distDir);
    return;
  case '.zip'
    unzip(url,distDir);
    return;
  case '.bz2'
    command = unbzipCommand;
  otherwise
    error(['Unknown archive extension ' ext]);
end 
    
vl_xmkdir(distDir);

% Download the file
archivePath = fullfile(pwd,distDir,[filename ext]);
wgetC = sprintf(wgetCommand,url,archivePath);

status = system(wgetC,'-echo');
if status ~= 0 
  delete(distDir);
  error('Error downloading, exit status %d',status); 
end

% Unpack the file
unpackC = sprintf(command,archivePath);

curDir = pwd;
cd(distDir)
try
  status = system(unpackC,'-echo');
  cd(curDir);
catch err
  cd(curDir)
  delete(distDir);
  throw(err);
end

if status ~= 0, error('Error unpacking %s',archivePath); end

% Clean the mess
if deleteArchive
  delete(archivePath);
end

end

