% Script to run benchmarks for different algorithms

detectors(1) = affineDetectors.vlFeatMser(); % Default options
%detectors(2) = affineDetectors.vlFeatDOG(); % Default options

affineDetectors.runBenchmark(detectors);
