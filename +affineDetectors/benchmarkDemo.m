function benchMarkDemo()
% BENCHMARKDEMO Script demonstrating how to run the benchmarks for
%   different algorithms.
%
%   The following datasets are supported right now:
%     <a href="matlab: help affineDetectors.vggDataset">affineDetectors.vggDataset</a>
%
%   The following detectors are supported right now:
%     <a href="matlab: help affineDetectors.vlFeatDOG">affineDetectors.vlFeatDOG</a>
%     <a href="matlab: help affineDetectors.vlFeatMser">affineDetectors.vlFeatMser</a>
%     <a href="matlab: help affineDetectors.vggAffine">affineDetectors.vggAffine</a>
%     <a href="matlab: help affineDetectors.vggMser">affineDetectors.vggMser</a>
%     <a href="matlab: help affineDetectors.sfop">affineDetectors.sfop</a>
%
%   See <a href="matlab: help affineDetectors.exampleDetector">affineDetectors.exampleDetector</a> on how to add your own detector

detectors{1} = affineDetectors.vlFeatDOG(); % Default options
detectors{2} = affineDetectors.vggMser('ms',30); % Custom options
detectors{3} = affineDetectors.vlFeatMser(); % Default options
detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the default name that is
% used in the plot legend by modifying the above field

dataset = affineDetectors.vggDataset('category','graf');

affineDetectors.runBenchmark(detectors,dataset,'ShowQualitative',false);
