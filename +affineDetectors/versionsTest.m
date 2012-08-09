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
clear mex;

import affineDetectors.*;

%detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian','Magnif',3,'AffRegionMagnif',12,'AffWinSize',39);
%detectors{1}.detectorName = 'VLf Hesaff (no or.) + mag.=12';
%detectors{1}.binPath{1} = vlf_old_aff;

magnif = 3;

detectors{1} = cmpHessian();

detectors{2} = vggNewAffine('Detector', 'hessian','NoAngle',false,'Magnification',magnif);
detectors{2}.detectorName = 'VGG nHesAff';

detectors{3} = vggNewAffine('Detector', 'hessian','NoAngle',true,'Magnification',magnif);
detectors{3}.detectorName = 'VGG nHesAff -noangle';

detectors{4} = vggAffine('Detector', 'hessian');

detectors{5} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian','Magnif',magnif);
detectors{5}.detectorName = 'VLf Hesaff + mag.';

detectors{5} = vlFeatCovdet('AffineAdaptation',true,'Orientation',true,'Method','hessian','Magnif',magnif);
detectors{5}.detectorName = 'VLf Hesaff or. + mag.';

%detectors{2} = affineDetectors.vggMser('ms',30); % Custom options
%detectors{3} = affineDetectors.vlFeatMser(); % Default options
%detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the default name that is
%detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
%detectors{1}.detectorName = 'VLf Hessian N-O approx. affine';

%vlf_old_aff = '/home/kaja/projects/c/vlfeat-old-aff-norm/toolbox/mex/mexa64/vl_covdet.mexa64';
%detectors{2} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
%detectors{2}.detectorName = 'VLf Hessian N-O slow affine';
%detectors{2}.binPath{1} = vlf_old_aff;

%detectors{3} = vlFeatCovdet('AffineAdaptation',true,'Orientation',true,'Method','hessian');
%detectors{3}.detectorName = 'VLf Hessian OR approx. affine';

%vlf_old_aff = '/home/kaja/projects/c/vlfeat-old-aff-norm/toolbox/mex/mexa64/vl_covdet.mexa64';
%detectors{4} = vlFeatCovdet('AffineAdaptation',true,'Orientation',true,'Method','hessian');
%detectors{4}.detectorName = 'VLf Hessian OR slow affine';
%detectors{4}.binPath{1} = vlf_old_aff;

%detectors{3} = cmpHessian();
%detectors{3}.detectorName = 'CMP Hessian N-O';
%detectors{4} = vggAffine('Detector', 'hessian');
%detectors{4}.detectorName = 'VGG Hessian N-O';

datasets{1} = vggDataset('category','graf');
datasets{2} = vggDataset('category','bark');
datasets{3} = vggDataset('category','bikes');
datasets{4} = vggDataset('category','boat');
datasets{5} = vggDataset('category','leuven');
datasets{6} = vggDataset('category','trees');
datasets{7} = vggDataset('category','ubc');
datasets{8} = vggDataset('category','wall');

if ~exist('tests','var') || isempty(tests)
  tests = cell(numel(datasets),1);
end
if ~exist('storages','var') || isempty(storages)
  storages = cell(numel(datasets),1);
end

for i=1
  % Initialise storage if it does not exist.
  storages = {};
  storages{i} = framesStorage(datasets{i}, 'calcDescriptors', true);
  storages{i}.addDetectors(detectors);

  if isempty(tests{i})
    %tests{i} = {repeatabilityTest(storages{i}) kristianEvalTest(storages{i},'CalcMatches',true)};
    tests{i} = {kristianEvalTest(storages{i},'CalcMatches',true)};
    %tests{i} = {repeatabilityTest(storages{i})};
  end
  % Run tests.
  for j=1:numel(tests{i})
    tests{i}{j}.runTest();
  end
end
