function unpack( url, distDir )
% UNPACK Unpack internet archive
%   UNPACK(URL, DIST_DIR) Unpack archive defined by URL to a DIST_DIR 
%   directory. Supports *.tar, *.tar.gz, *.tgz, *.zip archives.
%   For *.gz and *.bz2 archives (formats not supported by Matlab) 
%   needs  wget utility and gunzip + tar utility in the system path.

% Authors: Karel Lenc

% AUTORIGHTS
import helpers.*;

unbzipCommand = 'tar xvjf %s';
unTarGzipCommand = 'tar xvzf %s';
unGzipCommand = 'gunzip %s';
unZipCommand = 'unzip %s';
deleteArchive = true;

[address filename ext] = fileparts(url);
hasWget = commandExist('wget --version');

switch ext
  case '.gz'
    [d fn ext2] = fileparts(filename);
    if ~strcmp(ext2,'.tar')
      % Handle only gzipped single files
      command = unGzipCommand;
      deleteArchive = false;
    else
      command = unTarGzipCommand;
      if ~commandExist(command) || ~hasWget, untar(url,distDir);return;end
    end
  case {'.tar','.tgz'}
    command = unTarGzipCommand;
    if ~commandExist(command) || ~hasWget, untar(url,distDir); return; end
  case '.zip'
    command = unZipCommand;
    if ~commandExist(command) || ~hasWget, unzip(url,distDir); return; end
    return;
  case '.bz2'
    command = unbzipCommand;
  otherwise
    error(['Unknown archive extension ' ext]);
end 

if ~commandExist(command)
  error('Unpacking of the given archive not supported on your system.');
end

% Download the file
archivePath = helpers.downloadFile(url, distDir);

if isempty(archivePath)
  rmdir(distDir,'s');
  error('Error downloading file from %s.',url); 
end

% Unpack the file
unpackC = sprintf(command,fullfile(pwd,archivePath));

curDir = pwd;
cd(distDir)
try
  [status ret] = system(unpackC,'-echo');
  cd(curDir);
catch err
  cd(curDir)
  delete(distDir);
  throw(err);
end

if status ~= 0, error('Error unpacking %s: %s',archivePath,ret); end
% Clean the mess
if deleteArchive
  delete(archivePath);
end

  function res = commandExist(command)
    if ismember(computer,{'PCWIN','PCWIN64'})
      res = false; return;
    end;
    [ret drop] = system(command);
    % When command does not exist, it return error code 127
    res = (ret ~= 127);
  end

end
