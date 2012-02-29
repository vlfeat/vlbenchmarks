function cleanDeps()
% Function to delete all third party dependencies
import affineDetectors.*;

fprintf('\n----- Deleting datasets ----\n');
vggDataset.cleanDeps();

fprintf('\n-----  Deleting feature detectors -----\n');
vggMser.cleanDeps();
vggAffine.cleanDeps();
sfop.cleanDeps();
