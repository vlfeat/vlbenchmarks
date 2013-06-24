function repeatabilityDemo(resultsPath)
% REPEATABILITYDEMO Demonstrates how to run the repatability benchmark
%   REPEATABILITYDEMO() Runs the repeatability demo.
%
%   REPEATABILITYDEMO(RESULTS_PATH) Run the demo and save the results to
%   path RESULTS_PATH.

% Author: Karel Lenc and Andrea Vedaldi

% AUTORIGHTS

if nargin < 1, resultsPath = ''; end;

% --------------------------------------------------------------------
% PART 1: Image feature detectors
% --------------------------------------------------------------------

import datasets.*;
import benchmarks.*;
import localFeatures.*;
import consistencyModels.*;

% The feature detector/descriptor code is encapsualted in a corresponding
% class. For example, VLFeatSift() encapslate the SIFT implementation in
% VLFeat.
%
% In addition to wrapping the detector code, each object instance
% contains a specific setting of parameters (for example, the
% cornerness threshold). In order to compare different parameter
% settings, one simply creates multiple instances of these objects.

siftDetector = VlFeatSift();
thrSiftDetector = VlFeatSift('PeakThresh',11);

% VLBenchmarks enables a simple access to a number of public
% benchmakrs. It also provides simple facilities to generate test data
% on the fly. Here we generate an image consiting of a number of
% Gaussian blobs and we save it to disk for use with the detectors.

ellBlobs = datasets.helpers.genEllipticBlobs('Width',500,'Height',500,...
  'NumDeformations',4);
ellBlobsPath = 'ellBlobs.png';
imwrite(ellBlobs,ellBlobsPath);

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

siftFrames = siftDetector.extractFeatures(ellBlobsPath);
thrSiftFrames = thrSiftDetector.extractFeatures(ellBlobsPath);

% Now show the frames
figure(1); clf;
imshow(ellBlobs);
siftHandle = vl_plotframe(siftFrames,'g');
thrSiftHandle = vl_plotframe(thrSiftFrames,'r','LineWidth',1);
legend([siftHandle thrSiftHandle],'SIFT','SIFT PT=10','Location','SE');
helpers.printFigure(resultsPath,'siftFrames',0.9);

% --------------------------------------------------------------------
% PART 2: Detector repeatability
% --------------------------------------------------------------------

% A detector repeatability is measured against a benchmark. In this
% case we create an instance of the VGG Affine Testbed (graffity
% sequence).

dataset = datasets.VggAffineDataset('Category','graf');

% Next, the benchmark is intialised by choosing various
% parameters and geometric consistency model. The
% HomographyConsistencyModel corresponds to IJCV04 model where the ground
% truth is defined by homography between pair of images.

repBenchmark = RepeatabilityBenchmark(HomographyConsistencyModel(), ...
  'Mode','Repeatability');

% Prepare three detectors, the two from PART 1 and a third one that
% detects MSER image features.

mser = VlFeatMser();
featExtractors = {siftDetector, thrSiftDetector, mser};

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

repeatability = [];
numCorresp = [];

imageAPath = dataset.getImagePath(1);
for d = 1:numel(featExtractors)
  for i = 2:dataset.NumImages
    [repeatability(d,i) numCorresp(d,i)] = ...
      repBenchmark.testFeatureExtractor(featExtractors{d}, ...
                                dataset.getSceneGeometry(i), ...
                                dataset.getImagePath(1), ...
                                dataset.getImagePath(i));
  end
end

% The scores can now be prented, as well as visualized in a
% graph. This uses two simple functions defined below in this file.

detectorNames = {'SIFT','SIFT PT=10','MSER'};
printScores(detectorNames, 100 * repeatability, 'Repeatability');
printScores(detectorNames, numCorresp, 'Number of correspondences');

figure(2); clf; 
plotScores(detectorNames, dataset, 100 * repeatability, 'Repeatability');
helpers.printFigure(resultsPath,'repeatability',0.6);

figure(3); clf; 
plotScores(detectorNames, dataset, numCorresp, 'Number of correspondences');
helpers.printFigure(resultsPath,'numCorresp',0.6);

% Optionally, we can also see the matched frames itself. In this
% example we examine the matches between the reference and fourth
% image.
%
% We do this by running the repeatabiltiy score again. However, since
% the results are cached, this is fast.

imageBIdx = 3;

[drop drop siftSubsRes] = ...
  repBenchmark.testFeatureExtractor(siftDetector, ...
                            dataset.getSceneGeometry(imageBIdx), ...
                            dataset.getImagePath(1), ...
                            dataset.getImagePath(imageBIdx));

% And plot the feature frame correspondences

figure(4); clf;
imshow(dataset.getImagePath(imageBIdx));
benchmarks.helpers.plotFrameMatches(siftSubsRes,...
                                    'IsReferenceImage',false,...
                                    'PlotMatchLine',false,...
                                    'PlotUnmatched',false);
helpers.printFigure(resultsPath,'correspondences',0.75);

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

mserWithSift = DescriptorAdapter(mser, siftDetector);
featExtractors = {siftDetector, thrSiftDetector, mserWithSift};

% We create a benchmark object and run the tests as before, but in
% this case we request that descriptor-based matched should be tested.

matchingBenchmark = RepeatabilityBenchmark(HomographyConsistencyModel(), ...
  'Mode','MatchingScore');

matchScore = [];
numMatches = [];

for d = 1:numel(featExtractors)
  for i = 2:dataset.NumImages
    [matchScore(d,i) numMatches(d,i)] = ...
      matchingBenchmark.testFeatureExtractor(featExtractors{d}, ...
                                dataset.getSceneGeometry(i), ...
                                dataset.getImagePath(1), ...
                                dataset.getImagePath(i));
  end
end

% Print and plot the results

detectorNames = {'SIFT','SIFT PT=10','MSER with SIFT'};

printScores(detectorNames, matchScore*100, 'Match Score');
printScores(detectorNames, numMatches, 'Number of matches') ;

figure(5); clf; 
plotScores(detectorNames, dataset, matchScore*100,'Matching Score');
helpers.printFigure(resultsPath,'matchingScore',0.6);

figure(6); clf; 
plotScores(detectorNames, dataset, numMatches,'Number of matches');
helpers.printFigure(resultsPath,'numMatches',0.6);

% Same as with the correspondences, we can plot the matches based on
% feature frame descriptors. The code is nearly identical.

imageBIdx = 3;
[r nc siftSubsRes] = ...
  matchingBenchmark.testFeatureExtractor(siftDetector, ...
                            dataset.getSceneGeometry(imageBIdx), ...
                            dataset.getImagePath(1), ...
                            dataset.getImagePath(imageBIdx));

figure(7); clf;
imshow(imread(dataset.getImagePath(imageBIdx)));
benchmarks.helpers.plotFrameMatches(siftSubsRes,...
                                    'IsReferenceImage',false,...
                                    'PlotMatchLine',false,...
                                    'PlotUnmatched',false);
helpers.printFigure(resultsPath,'matches',0.75);

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
  xLabel = dataset.ImageNamesLabel;
  xTicks = dataset.ImageNames;
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