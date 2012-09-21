function benchmarkDemo()
% BENCHMARKDEMO Demonstrates how to run the feature repatability benchmark

% Author: Karel Lenc and Andrea Vedaldi

% AUTORIGHTS

import localFeatures.*;

% --------------------------------------------------------------------
% PART 1: Detectors, visualization, and caching
% --------------------------------------------------------------------

% The feature detector/descriptor code is encapsualted in a corresponding.
% For example, VLFeatSift() encapslate the SIFT implementation in
% VLFeat.
%
% In addition to wrapping the detector code, each object instance
% contains a specific setting of parameters (for example, the
% cornerness threshold). In order to compare different parameter
% settings, one simply creates multiple instances of these objects.

siftDetector = VlFeatSift();
mserDetector = VlFeatMser('MinDiversity',0.5);

% VLBenchmarks enables a simple access to a number of public
% benchmakrs. It also provides simple facilities to generate test data
% on the fly. Here we generate an image consiting of a number of
% Gaussian blobs and we save it to disk for use with the detectors.

ellImage = datasets.helpers.genEllipticBlobs(...
  'NumDeformations', 3,...
  'Width', 400,...
  'Height', 400);

ellImagePath = [tempname '.png'];
imwrite(ellImage,ellImagePath);

% Next, we extract the features by running the detectors we
% prepared.
%
% VLBeanchmarks is smart. The detector output is cached (for each
% input image and parameter setting), so the next time the detector is
% called the output is read from disk rather than being comptued
% again. VLBenchmarks automatically checks whether the detector
% parameters, image, or code change based on their modification date
% and invalidates the cache if necessary. You can also invoke the
% disableCaching() method in each detector to prevent it from caching.

siftFrames = siftDetector.extractFeatures(ellImagePath) ;
mserFrames = mserDetector.extractFeatures(ellImagePath) ;

% Now show the frames
figure(1); clf;
subplot(1,2,1); imshow(ellImage);
vl_plotframe(siftFrames,'LineWidth',1); title('SIFT frames');
subplot(1,2,2); imshow(ellImage);
vl_plotframe(mserFrames,'r','LineWidth',1); title('MSER frames');

% --------------------------------------------------------------------
% PART 2: Detector repeatability
% --------------------------------------------------------------------

import datasets.*;
import benchmarks.*;

% A detector repeatability is measured against a benchmark. In this
% case we create an instance of the VGG Affine Testbed (graffity
% sequence).

dataset = VggAffineDataset('category','graf');

% Next, the benchmark is intialised by choosing various
% parameters. The defaults correspond to the seetting in the original
% publication (IJCV05).

repBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,... % Do create one-to-one matches from overlaps
  'MatchFramesDescriptors',false,... % Do not use descriptors for matching
  'CropFrames',true,... % Crop the frames out of overlap regions
  'NormaliseFrames',true,... % Normalise frame scale
  'OverlapError',0.4); % Maximal overlap error for frame match

% Prepare three detectors, the two from PART 1 and a third one that
% simply detects features on a grid.

detectors{1} = siftDetector ;
detectors{2} = mserDetector ;
detectors{3} = ExampleLocalFeatureExtractor('Scales',5:5:25, ...
                                            'FramesDistance',5) ;

% Now we are ready to run the repeatability test. We do this by fixing
% a reference image A and looping through other images B in the
% set. To this end we use the following information:
%
% dataset.NumImages:
%    Number of images in the dataset.
%
% dataset.getImagePath(i):
%    Path to the i-th image.
%
% dataset.getTransformation(i):
%    Transformation from the first (reference) image to image i.
%
% Like for the detector output (see PART 1), VLBenchmarks caches the
% output of the test. This can be disabled by calling
% repBenchmark.disableCaching().

repeatability = [] ;
numCorresp = [] ;
for d = 1:numel(detectors)
  for i = 2:dataset.NumImages
    [repeatability(d,i) numCorresp(d,i)] = ...
      repBenchmark.testDetector(detectors{d}, ...
                                dataset.getTransformation(i), ...
                                dataset.getImagePath(1), ...
                                dataset.getImagePath(i)) ;
  end
end

% The scores can now be prented, as well as visualized in a
% graph. This uses two simple functions defined below in this file.

detectorNames = {'SIFT','MSER','Features on a grid'};
printScores(detectorNames, 100 * repeatability, 'Repeatability');
printScores(detectorNames, numCorresp, 'Number of correspondences');

figure(2); clf;
subplot(1,2,1);
plotScores(detectorNames, dataset, 100 * repeatability, 'Repeatability');
subplot(1,2,2);
plotScores(detectorNames, dataset, numCorresp, 'Number of correspondences');

% Optionally, we can also see the matched frames itself. In this
% example we examine the matches between the reference and fourth
% image.
%
% We do this by running the repeatabiltiy score again. However, since
% the results are cached, this is fast.

imageBIdx = 4 ;

[drop drop siftCorresps siftReprojFrames] = ...
  repBenchmark.testDetector(siftDetector, ...
                            dataset.getTransformation(imageBIdx), ...
                            dataset.getImagePath(1), ...
                            dataset.getImagePath(imageBIdx)) ;

[drop drop mserCorresps mserReprojFrames] = ...
    repBenchmark.testDetector(mserDetector, ...
                              dataset.getTransformation(imageBIdx), ...
                              dataset.getImagePath(1), ...
                              dataset.getImagePath(imageBIdx)) ;

% And plot the feature frame correspondences
figure(3); clf;
image = imread(dataset.getImagePath(imageBIdx)) ;

subplot(1,2,1); imshow(image);
benchmarks.helpers.plotFrameMatches(siftCorresps, ...
                                    siftReprojFrames,...
                                    'IsReferenceImage',false);
title(sprintf('SIFT Correspondences with %d image (%s dataset).',...
              imageBIdx,dataset.DatasetName));

subplot(1,2,2); imshow(image);
benchmarks.helpers.plotFrameMatches(mserCorresps, ...
                                    mserReprojFrames,...
                                    'IsReferenceImage',false);
title(sprintf('MSER Correspondences with %d image (%s dataset).',...
              imageBIdx,dataset.DatasetName));

% --------------------------------------------------------------------
% PART 3: Detector matching score
% --------------------------------------------------------------------

% The matching score is similar to the repeatability score, but
% involves computing a descriptor. Detectors like SIFT bundle a
% descriptor as well. However, most of them (e.g. MSER) do not have an
% associated descriptor (e.g. MSER). In this case we can bind one of
% our choice by using the DescriptorAdapter class.
%
% In this particular example, the object encapsulating the SIFT
% detector is used as descriptor form MSER.

detectors{1} = siftDetector ;
detectors{2} = DescriptorAdapter(mserDetector,siftDetector) ;

% As an additional example, we show how to use a different descriptor
% for the SIFT detector. In this case, we bind the descriptor
% implemented by the ExampleLocalFeatureExtractor() class which simply
% computes the mean, standard deviation, and median of a patch.
%
% Note that in this manner the SIFT descriptor is replaced by the new
% descriptor.

meanVarMedianDescExtractor = ExampleLocalFeatureExtractor();
detectors{3} = DescriptorAdapter(siftDetector,meanVarMedianDescExtractor);

% We create a benchmark object and run the tests as before, but in
% this case we request that descriptor-based matched should be tested.

matchBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',true,... % Match both geometry and descriptors
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);

matchScore = [] ;
numMatches = [] ;
for d = 1:numel(detectors)
  for i = 2:dataset.NumImages
    [matchScore(d,i) numMatches(d,i)] = ...
      repBenchmark.testDetector(detectors{d}, ...
                                dataset.getTransformation(i), ...
                                dataset.getImagePath(1), ...
                                dataset.getImagePath(i)) ;
  end
end

% Print and plot the results

detectorNames = {'SIFT', ...
                 'MSER + Sim. inv. SIFT desc.', ...
                 'SIFT frames + Mean/Var/Med desc.' };

printScores(detectorNames, matchScore*100, 'Match Score');
printScores(detectorNames, numMatches, 'Number of matches') ;

figure(4); clf;
subplot(1,2,1);
plotScores(detectorNames, dataset, matchScore*100,'Matching Score');
subplot(1,2,2);
plotScores(detectorNames, dataset, numMatches,'Number of matches');

% Same as with the correspondences, we can plot the matches based on
% feature frame descriptors. The code is nearly identical.

imageBIdx = 4 ;

[drop drop siftMatches siftReprojFrames] = ...
  repBenchmark.testDetector(siftDetector, ...
                            dataset.getTransformation(imageBIdx), ...
                            dataset.getImagePath(1), ...
                            dataset.getImagePath(imageBIdx)) ;

[drop drop mvmMatches mvmReprojFrames] = ...
    repBenchmark.testDetector(meanVarMedianDescExtractor, ...
                              dataset.getTransformation(imageBIdx), ...
                              dataset.getImagePath(1), ...
                              dataset.getImagePath(imageBIdx)) ;

figure(5); clf;
image = imread(dataset.getImagePath(imageBIdx));
subplot(1,2,1); imshow(image);

benchmarks.helpers.plotFrameMatches(siftMatches, siftReprojFrames,...
                                    'IsReferenceImage',false);
title(sprintf('SIFT Matches with %d image (%s dataset).',...
              imageBIdx,dataset.DatasetName));

subplot(1,2,2); imshow(image);
benchmarks.helpers.plotFrameMatches(mvmMatches, mvmReprojFrames,...
  'IsReferenceImage',false);
title(sprintf('Matches using mean-variance-median descriptor with %d image (%s dataset).',...
              imageBIdx,dataset.DatasetName));

% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------

function printScores(detectorNames, scores, name)
  numDetectors = numel(detectorNames);
  maxNameLen = length('Method name');
  for k = 1:numDetectors
    maxNameLen = max(maxNameLen,length(detectorNames{k}));
  end
  fprintf(['\n', name,':\n']);
  formatString = ['%' sprintf('%d',maxNameLen) 's:'];
  fprintf(formatString,'Method name');
  for k = 2:size(scores,2)
    fprintf('\tImg#%02d',k);
  end
  fprintf('\n');
  for k = 1:numDetectors
    fprintf(formatString,detectorNames{k});
    for l = 2:size(scores,2)
      fprintf('\t%6s',sprintf('%.2f',scores(k,l)));
    end
    fprintf('\n');
  end
end

function plotScores(detectorNames, dataset, score, titleText)
  xstart = max([find(sum(score,1) == 0, 1) + 1 1]);
  xend = size(score,2);
  xLabel = dataset.imageNamesLabel;
  xTicks = dataset.imageNames;
  plot(xstart:xend,score(:,xstart:xend)','+-','linewidth', 2); hold on ;
  ylabel(titleText) ;
  xlabel(xLabel);
  set(gca,'XTick',xstart:1:xend);
  set(gca,'XTickLabel',xTicks);
  title(titleText);
  set(gca,'xtick',1:size(score,2));
  maxScore = max([max(max(score)) 1]);
  meanEndValue = mean(score(:,xend));
  legendLocation = 'SouthEast';
  if meanEndValue < maxScore/2
    legendLocation = 'NorthEast';
  end
  legend(detectorNames,'Location',legendLocation);
  grid on ;
  axis([xstart xend 0 maxScore]);
end

end
