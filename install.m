function install()
% INSTALL Install benchmarks and its basic support tools

% Authors: Karel Lenc

% AUTORIGHTS

% Installs VLFeat and compiles mex files needed for the benchmarking
% code. This script does not install any detector apart from VLFeat
% detectors and detectors with Matlab implementation. Other
% detectors or datasets are installed on demand during the wrapper
% object construction.

installers = {...
  helpers.VlFeatInstaller(),...
  helpers.Installer(), ...
  benchmarks.RepeatabilityBenchmark(),...
  benchmarks.IjcvOriginalBenchmark(),...
  benchmarks.RetrievalBenchmark()
  };

for installer=installers
  installer{:}.install();
end