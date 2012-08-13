function installDeps()
% Function to install all third party dependencies
import affineDetectors.*;

fprintf('\n----- Downloading and installing datasets ----\n');
vggDataset.installDeps();

fprintf('\n----- Downloading and installing feature detectors -----\n');
vggMser.installDeps();
vggAffine.installDeps();
sfop.installDeps();
cmpHessian.installDeps();

installKristianBenchmark();
installCalcMD5();

function installCalcMD5()
  curDir = pwd;
  cd(fullfile(pwd,'+helpers','+CalcMD5'));
  mexCmd = 'mex -O CalcMD5.c';
  fprintf('Compiling: %s\n',mexCmd);
  eval(mexCmd);
  cd(curDir);
end

function installKristianBenchmark()

import affineDetectors.*;

fprintf('\n------ Downloading and installing Kristian''s benchmark -----\n');

installDir = helpers.getKristianDir();
if(exist(installDir,'dir')),
  fprintf('Kristian''s benchmark already installed\n');
  return;
end

url = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz';

try
  untar(url,installDir);
catch err
  warning('Error downloading from: %s\n',url);
  fprintf('Following error was reported while untarring: %s\n',...
          err.message);
end

curDir = pwd;
cd(installDir);
mexCmd = 'mex -O c_eoverlap.cxx';
fprintf('Compiling: %s\n',mexCmd);
eval(mexCmd);

cd(curDir);



fprintf('Done!\n');
end
end
