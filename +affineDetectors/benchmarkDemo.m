% Script to run benchmarks for different algorithms

detectors{1} = affineDetectors.vggMser(); % Default options
detectors{2} = affineDetectors.vlFeatDOG(); % Default options
detectors{3} = affineDetectors.vlFeatMser(); % Default options
%detectors{1} = affineDetectors.vlFeatMser('delta',5,'maxArea',0.75,...
    %'minArea',0,'maxVariation',0.25,'minDiversity',0.2); % Default options

affineDetectors.runBenchmark(detectors);
