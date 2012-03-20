function benchMarkDemo()
% Script to run benchmarks for different algorithms
% Making it a function, so that variables don't clutter workspace

%detectors{1} = affineDetectors.vlFeatDOG(); % Default options
%detectors{2} = affineDetectors.vggMser('ms',300); % Custom options
%detectors{3} = affineDetectors.vlFeatMser('minarea',0.001); % Custom options
%detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the name that is
% used for displaying results from the default also.
detectors{1} = affineDetectors.cmpHessian();
%detectors{5} = affineDetectors.vggAffine('Detector', 'hessian');
%detectors{6} = affineDetectors.vggAffine('Detector', 'harris');
% See affineDetectors.exampleDetector on how to add your own detector

dataset = affineDetectors.vggDataset('category','graf');

affineDetectors.runBenchmark(detectors,dataset,'verifyKristian',true, ...
                             'ShowQualitative',false);
