% Script to run benchmarks for different algorithms

detectors{1} = affineDetectors.vggMser(); % Default options
detectors{2} = affineDetectors.vlFeatDOG(); % Default options
detectors{3} = affineDetectors.vlFeatMser(); % Default options

dataset = affineDetectors.vggDataset('category','graf');

affineDetectors.runBenchmark(detectors,dataset);
