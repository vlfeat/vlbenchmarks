function installDir = getKristianDir()

cwd = commonFns.extractDirPath(mfilename('fullpath'));
installDir = fullfile(cwd,'..','thirdParty','repeatability');
