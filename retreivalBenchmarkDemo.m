function retreivalBenchmarkDemo()

%% Define Local features detectors

import localFeatures.*;

detectors{1} = vggMser('ms',30); % Custom options
detectors{2} = vlFeatMser(); % Default options
detectors{2}.detectorName = 'VLFeat MSER'; % used in the plot legend by modifying the above field
detectors{3} = cmpHessian();
detectors{4} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
detectors{5} = vggAffine('Detector', 'hessian');
detectors{6} = vggNewAffine('Detector', 'hessian');

%% Define dataset

import datasets.*;

dataset = vggRetrievalDataset('category','oxbuild_lite');

%% Define benchmarks

import benchmarks.*;

retBenchmark = retrievalBenchmark();

%% Run the benchmark
detector = detectors{1}; % CMP hessian

mAP = retBenchmark.evalDetector(detector, dataset);


%% Show scores




%% Helper functions

end
