function installDeps()
% Function to install all third party dependencies
import affineDetectors.*;

fprintf('\n----- Downloading and installing datasets ----\n');
vggDataset.installDeps();

fprintf('\n----- Downloading and installing feature detectors -----\n');
vggMser.installDeps();
vggAffine.installDeps();
sfop.installDeps();
