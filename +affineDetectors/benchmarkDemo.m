% Script to run benchmarks for different algorithms

detectors{1} = affineDetectors.vlFeatDOG(); % Default options
detectors{2} = affineDetectors.vlFeatMser(); % Default options

affineDetectors.runBenchmark(detectors);
