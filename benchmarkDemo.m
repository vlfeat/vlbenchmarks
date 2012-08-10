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
%global storage
%global tests

%detectors{1} = vlFeatDOG('PeakThresh',3/255); % Default options
%detectors{1} = cmpCensure('detectorType',1);
%detectors{2} = cmpCensure('detectorType',0);
octRatios = [1.5,2.0,2.5,3.0,4.0];
thresholds=[35,40,40,40,40];
i=2;
%for octRatio = octRatios
%  detectors{i} = cmpCensure('octRatio',octRatio,'respThr',thresholds(i-1));
%  detectors{i}.detectorName = ['Censure octRat=' num2str(octRatio)];
%  i = i + 1;
%end
detectors{1} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5);
detectors{1}.detectorName = 'Censure initRad= 2.5';
detectors{2} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',3.5);
detectors{2}.detectorName = 'Censure initRad= 3.5';
detectors{3} = starDetector('response_threshold',30);
%detectors{4} = vlFeatDOG('PeakThresh',3/255);
%detectors{2} = affineDetectors.vggMser('ms',30); % Custom options
%detectors{3} = affineDetectors.vlFeatMser(); % Default options
%detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the default name that is
% used in the plot legend by modifying the above field
%detectors{1} = cmpHessian();
%detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',true,'Method','hessian');
%detectors{3} = vggAffine('Detector', 'hessian');
%detectors{3} = affineDetectors.vggAffine('Detector', 'harris');

%%% Orientation test
%detectors{1} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5,'KPdef',1);
%detectors{1}.detectorName = 'Censure with orient.';
%detectors{2} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5);
%detectors{2}.detectorName = 'Censure';


datasets{1} = vggDataset('category','graf');
datasets{2} = vggDataset('category','bark');
datasets{3} = vggDataset('category','bikes');
datasets{4} = vggDataset('category','boat');
datasets{5} = vggDataset('category','leuven');
datasets{6} = vggDataset('category','trees');
datasets{7} = vggDataset('category','ubc');
datasets{8} = vggDataset('category','wall');

datasets{9} = transfDataset('image','boat.pgm','numImages',11,'category',{'zoom'},'startZoom',1,'endZoom',0.25);

for i=4
  % Initialise storage if it does not exist.
  storage = framesStorage(datasets{i}, 'calcDescriptors', true);
  storage.addDetectors(detectors);

  % TODO solve where to store tests - cell is not ideal storage because it
  % does not support adding new tests on demand...
  %tests = {repeatabilityTest(storage,'showQualitative',[])};
  %tests = {repeatabilityTest(storage), kristianEvalTest(storage)};
  %tests = {repeatabilityTest(storage),kristianEvalTest(storage,'CalcMatches',false)};
  tests = {kristianEvalTest(storage,'CalcMatches',true)};
  % Run tests.
  for j=1:numel(tests)
    tests{j}.runTest();
  end
end
