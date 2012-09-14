function [mAP quertAPs] = retrievalBenchmarkDemo()
% RETRIEVALBENCHMARKDEMO Demo of retrieval benchmark usage
import localFeatures.*;
import datasets.*;
import benchmarks.*;

%% Define Local features detectors
detectors{1} = vggAffine('Detector','haraff');
detectors{2} = vggAffine('Detector','hesaff');
detectors{3} = cmpBinHessian();
% For MSERs use VGG SIFT as descriptors
detectors{4} = descriptorAdapter(vggMser(),vggAffine());

detNames = {'VGG MSER + VGG SIFT','VGG Harris Affine',...
  'VGG Hessian Affine','CMP Hessian Affine'};

%% Define dataset
dataset = vggRetrievalDataset('Category','oxbuild','Lite',true);

%% Run the benchmark
retBenchmark = RetrievalBenchmark();

mAP = zeros(numel(detectors),1);
quertAPs = cell(numel(detectors),1);

for d=1:numel(detectors)
  [mAP(d) quertAPs{d}]  = retBenchmark.evalDetector(detectors{d}, dataset);
end

