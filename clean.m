function clean(varargin)
% CLEAN Clean installed resources and cached data.
%   CLEAN() Clean all installed files by install script.
%
%   CLEAN('OptionName',OptionValue) Specify additional options.
%
% Function accepts following options:
%
%   Datasets:: false
%     Clean all datasets.
%
%   Cache:: false
%     Delete all cached data.

% Authors: Karel Lenc

% AUTORIGHTS
import helpers.*;

opts.datasets = false;
opts.cache = false;
opts = vl_argparse(opts,varargin);
noInstArgs = {'AutoInstall',false};
installers = {...
  VlFeatInstaller(),...
  Installer(), ...
  YaelInstaller(),...
  benchmarks.RepeatabilityBenchmark(noInstArgs{:}),...
  benchmarks.IjcvOriginalBenchmark(noInstArgs{:}),...
  benchmarks.RetrievalBenchmark(noInstArgs{:}),...
  benchmarks.helpers.Installer()...
  };
if opts.datasets
  installers = {installers,...
    datasets.VggRetrievalDataset(noInstArgs{:}),...
    datasets.VggAffineDataset(noInstArgs{:})};
end
for installer=installers
  installer{:}.clean();
end

if opts.cache
  DataCache.deleteAllCachedData();
end
end