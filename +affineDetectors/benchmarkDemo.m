function benchmarkDemo()
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

import affineDetectors.*;
global storage;
global tests;

detectors{1} = vlFeatDOG(); % Default options
%detectors{2} = affineDetectors.vggMser('ms',30); % Custom options
%detectors{3} = affineDetectors.vlFeatMser(); % Default options
%detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the default name that is
% used in the plot legend by modifying the above field
detectors{2} = cmpHessian();
%detectors{3} = vlFeatHessian();
%detectors{3} = vggAffine('Detector', 'hessian');
%detectors{3} = affineDetectors.vggAffine('Detector', 'harris');

dataset = vggDataset('category','graf');

% Initialise storage if it does not exist.
if isempty(storage)
  storage = framesStorage(dataset);
end

% TODO solve where to store tests - cell is not ideal storage because it
% does not support adding new tests on demand...
if isempty(tests)
  tests = {repeatabilityTest(storage), kristianEvalTest(storage)};
end

storage.addDetectors(detectors);

% Run tests.
for i=1:numel(tests)
  tests{i}.runTest();
end
