function clean(varargin)
% CLEAN Clean installed resources.
%   CLEAN() Clean all installed files by install script.
%   CLEAN('All',true) Clean all installed modules.
import helpers.*;

opts.all = false;
opts = vl_argparse(opts,varargin);
noInstArgs = {'AutoInstall',false};
installers = {...
  VlFeatInstaller(),...
  Installer(), ...
  benchmarks.RepeatabilityBenchmark(noInstArgs{:}), ...
  benchmarks.IjcvOriginalBenchmark(noInstArgs{:})
  };
if opts.all
  installers = [installers,...
    OpenCVInstaller(),...
    YaelInstaller(),...
    datasets.VggAffineDataset(noInstArgs{:}),...
    datasets.VggRetrievalDataset(noInstArgs{:}),...
    benchmarks.RetrievalBenchmark(noInstArgs{:})];
end
for installer=installers
  installer{:}.clean();
end

DataCache.deleteAllCachedData();

end