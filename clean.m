function clean()
% Function to clean all third party dependencies

affineDetectors.cleanDeps();
cleanVlFeat();

function cleanVlFeat()

  fprintf('\n----- Deleting vlfeat -----\n');

  cwd=commonFns.extractDirPath(mfilename('fullpath'));
  installVersion = '0.9.14';
  installDir = fullfile(cwd,'thirdParty');
  vlFeatDir = fullfile(installDir,['vlfeat-' installVersion]);

  if(exist(vlFeatDir,'dir'))
    rmdir(vlFeatDir,'s');
  end

  fprintf('Done!\n');
