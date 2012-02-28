function benchMarkDemo()
% Script to run benchmarks for different algorithms
% Making it a function, so that variables don't clutter workspace

detectors{1} = affineDetectors.vlFeatDOG(); % Default options
detectors{2} = affineDetectors.vggMser('ms',300); % Custom options
detectors{3} = affineDetectors.vlFeatMser('minarea',0.001); % Custom options

dataset = affineDetectors.vggDataset('category','graf');

affineDetectors.runBenchmark(detectors,dataset);
