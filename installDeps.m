function installDeps()
% Function to install all third party dependencies

affineDetectors.installDeps();

installVlFeat();

function installVlFeat()

  fprintf('\n----- Downloading and setting up vlfeat -----\n');
  % Check if vl feat functions are already in path, if yes, then do nothing
  if(exist('vl_demo','file')),
    fprintf('VLFeat already installed and loaded\n');
    return;
  end

  cwd=commonFns.extractDirPath(mfilename('fullpath'));
  installVersion = '0.9.14';
  installDir = fullfile(cwd,'thirdParty');
  commonFns.vl_xmkdir(installDir);
  vlFeatDir = fullfile(installDir,['vlfeat-' installVersion]);

  % If vlfeat is already downloaded, then just run setup.m
  if(exist(vlFeatDir,'dir'))
    fprintf('VLFeat is already downloaded, setting up paths ...\n');
    run(fullfile(vlFeatDir,'toolbox','vl_setup.m'));
    fprintf('Done!\n');
    return;
  end

  fprintf('Downloading and extracting vlfeat-%s-bin.tar.gz (takes a few minutes) ...\n',installVersion);
  softwareUrl = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz',...
                         installVersion);
  untar(softwareUrl,installDir);
  run(fullfile(vlFeatDir,'toolbox','vl_setup.m'));
  fprintf('Done!\n');
