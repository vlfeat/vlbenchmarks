function install()
% INSTALL Install benchmarks and its basic support tools

%   Instal
ls VLFeat and compiles mex files needed for the benchmarking
%   code. This script does not install any detector apart from VLFeat
%   detectors and detectors with Matlab implementation. Other
%   detectors or datasets are installed on demand during the wrapper
%   object construction.

installers = {...
  helpers.VlFeatInstaller('0.9.15'),...
  helpers.Installer(), ...
  benchmarks.RepeatabilityBenchmark(), ...
  benchmarks.IjcvOriginalBenchmark()
  };

for installer=installers
  installer{:}.install();
end