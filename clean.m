function clean()
% Function to clean all third party dependencies

localFeatures.cleanDeps();
cleanVlFeat();

function cleanVlFeat()

  fprintf('\n----- Deleting vlfeat -----\n');

  installVersion = '0.9.14';
  installDir = fullfile('data','software','');
  vlFeatDir = fullfile(installDir,['vlfeat-' installVersion]);

  if(exist(vlFeatDir,'dir'))
    rmdir(vlFeatDir,'s');
    fprintf('VLFeat deleted.\n');
  else
    fprintf('VLFeat not installed, nothing to delete\n');
  end
