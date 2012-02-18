function installDeps()
% Function to install all third party dependencies
import affineDetectors.*;

fprintf('\nDownloading and installing datasets ...\n\n');
vggDataset.installDeps();
