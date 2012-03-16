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
detectors{2} = affineDetectors.vggMser('ms',300); % Custom options
detectors{3} = affineDetectors.vlFeatMser('minarea',0.001); % Custom options
detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the name that is
% used for displaying results from the default also.

%detectors{1} = affineDetectors.vggAffine('detector','hessian');
%detectors{2} = affineDetectors.vggAffine('detector','harris');
%detectors{3} = affineDetectors.vggMser();


dataset = affineDetectors.vggDataset('category','graf');

%affineDetectors.runBenchmark(detectors,dataset,'verifyKristian',true);
affineDetectors.runBenchmark(detectors,dataset);
