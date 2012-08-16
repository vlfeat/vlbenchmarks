%% Define Local features detectors
setup
import localFeatures.*;

detectors{1} = vggMser('ms',30); % Custom options
%detectors{2} = vlFeatMser(); % Default options
%detectors{2}.detectorName = 'VLFeat MSER'; % used in the plot legend by modifying the above field
%detectors{3} = cmpHessian();
detectors{2} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
detectors{3} = vggAffine('Detector', 'hessian');
%detectors{6} = vggNewAffine('Detector', 'hessian');
detectors{4} = randomFeaturesGenerator();

%% Define dataset

import datasets.*;

dataset = vggRetrievalDataset('category','oxbuild_lite');

%% Define benchmarks

import benchmarks.*;

retBenchmark = retrievalBenchmark();

%% Run the benchmark

for i = 1:numel(detectors)
detector = detectors{i};
res = retBenchmark.findApproxFactor(detector, dataset);
[appFactors,missingFeatRatio(i,:),featDistRatio(i,:),idxError(i,:),distRatio(i,:)] = res{:};

end

%%
figure(1); clf;
subplot(2,2,1);hold on; grid on;
plot(appFactors, missingFeatRatio); title('Number of missing features per query');
xlabel('MaxComparisonsFactor f (m.c. = f*k)');

subplot(2,2,2);hold on; grid on;
plot(appFactors, featDistRatio); title('Average distance ratio between same features');
xlabel('MaxComparisonsFactor f (m.c. = f*k)');

subplot(2,2,3);hold on; grid on;
plot(appFactors, idxError); title('% of wrong indexes');
xlabel('MaxComparisonsFactor f (m.c. = f*k)');

subplot(2,2,4);hold on; grid on;
plot(appFactors, distRatio); title('Distance ratio');
xlabel('MaxComparisonsFactor f (m.c. = f*k)');


detnames = cellfun(@(c) c.detectorName, detectors, 'UniformOutput', false);
legend(detnames); 

