function cleanDeps()
% Function to delete all third party dependencies
import affineDetectors.*;

fprintf('\n----- Deleting datasets ----\n');
vggDataset.cleanDeps();

fprintf('\n-----  Deleting feature detectors -----\n');
vggMser.cleanDeps();
vggAffine.cleanDeps();
sfop.cleanDeps();
cmpHessian.cleanDeps();

cleanKristian();

function cleanKristian()

import affineDetectors.*;

fprintf('\n-----  Deleting Kristian''s code -----\n');

installDir = helpers.getKristianDir();
if(exist(installDir,'dir')),
  rmdir(installDir,'s');
  fprintf('Kristian''s code deleted\n');
else
  fprintf('Kristians'' code not installed, nothing to delete\n');
end
