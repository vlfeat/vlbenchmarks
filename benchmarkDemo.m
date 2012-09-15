function benchmarkDemo()
% BENCHMARKDEMO Script demonstrating how to run the repeatability 
%   benchmarks for different algorithms.
%

%% Local Features Detectors
import localFeatures.*;

% Create instances of detectors
% Create sift detector with default parameters.
siftDetector = VlFeatSift();
% Each instance holds detector parameters which are used as a part of
% detector signature. This signature is used for caching extracted
% features.
mserDetector = VlFeatMser('MinDiversity',0.5);

% Now create a testing image with affine blobs
ellImage = datasets.helpers.genEllipticBlobs('NumDeformations',3,...
  'Width',400,'Height',400);
% However in order to be able to use it in the detectors, it must be saved
% into a file.
ellImagePath = [tempname '.png'];
imwrite(ellImage,ellImagePath);

% Run the feature frame detectors
siftFrames = siftDetector.extractFeatures(ellImagePath);
mserFrames = mserDetector.extractFeatures(ellImagePath);

% Now the frames detected in the image 'ellImagePath' are stored in the
% cache. Next time extractFeatures on the same detectors with the same
% settings and on the same image will be called, frames would be loaded 
% from the cache. 
% Because the data in the image can change, features are stored according
% to its last modification date. Same holds also for the descriptor binary.
% If you want to disable caching, call detector method disableCaching().

% Now show the frames
figure(1); subplot(1,2,1);
imshow(ellImage); vl_plotframe(siftFrames,'LineWidth',1); title('SIFT frames');
subplot(1,2,2);
imshow(ellImage); vl_plotframe(mserFrames,'r','LineWidth',1); title('MSER frames');


%% Detectors repeatability
import datasets.*;
import benchmarks.*;
% For measuring repeatability we have to define a dataset.
dataset = VggAffineDataset('category','graf');

% And define the repeatability benchmark as it is defined in IJCV05 article
repBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,... % Do create one-to-one matches from overlaps
  'MatchFramesDescriptors',false,... % Do not use descriptors for matching
  'CropFrames',true,... % Crop the frames out of overlap regions
  'NormaliseFrames',true,... % Normalise frame scale
  'OverlapError',0.4); % Maximal overlap error for frame match

% Define set of tested detector
detectors{1} = siftDetector;
detectors{2} = mserDetector;
% We add another detector, which simply generates grid of frames on the
% input image
gridGenerator = ExampleLocalFeatureExtractor(...
  'Scales',5:5:25, ... % Scales of the generated frames
  'framesDistance',5); % Distance between each frame (mult. of its scale)
detectors{3} = gridGenerator;

% Prealocate the results
numDetectors = numel(detectors);
numImages = dataset.numImages;
repeatability = zeros(numDetectors, numImages);
numCorresp = zeros(numDetectors, numImages);

% Get the path to reference image
imageAPath = dataset.getImagePath(1);
% Test all detectors on all images in the dataset
for detectorIdx = 1:numDetectors
  detector = detectors{detectorIdx};
  for imageIdx = 2:numImages
    % Get path to the tested image and the homography between the reference
    % and the tested image
    imageBPath = dataset.getImagePath(imageIdx);
    tf = dataset.getTransformation(imageIdx);
    % Run the test. Because it is possible to uniquely specify the results 
    % by the properties of the detector and the tested images, the computed 
    % values are cached. This can be disabled by calling 
    % repBenchmark.disableCaching()
    [repeatability(detectorIdx,imageIdx) numCorresp(detectorIdx,imageIdx)] = ...
      repBenchmark.testDetector(detector, tf, imageAPath,imageBPath);
  end
end

% Using helper functions, print and plot the scores
detectorNames = {'SIFT','MSER','Features on a grid'};
figure(2); clf; 
printScores(detectorNames, repeatability.*100, 'Repeatability');
subplot(1,2,1); 
plotScores(detectorNames, dataset, repeatability.*100,'Repeatability');
printScores(detectorNames, numCorresp, 'Number of correspondences');
subplot(1,2,2);
plotScores(detectorNames, dataset, numCorresp, 'Number of correspondences');

% We can also see the matched frames itself. For example we want to see the
% matches between reference and the fourth image.
imageBIdx = 4;
imageBPath = dataset.getImagePath(imageBIdx);
tf = dataset.getTransformation(imageBIdx);
% Now we need to get the reprojected frames and thei correspondences.
% Because these results have been already calculated they are
% loaded from cache.
[drop drop siftCorresps siftReprojFrames] = ...
  repBenchmark.testDetector(siftDetector, tf, imageAPath,imageBPath);
[drop drop mserCorresps mserReprojFrames] = ...
  repBenchmark.testDetector(mserDetector, tf, imageAPath,imageBPath);
    
% And plot the feature frame correspondences
figure(3); clf;
image = imread(imageBPath);
subplot(1,2,1); imshow(image);

benchmarks.helpers.plotFrameMatches(siftCorresps, siftReprojFrames,...
  'IsReferenceImage',false);
title(sprintf('SIFT Correspondences with %d image (%s dataset).',...
  imageBIdx,dataset.datasetName));

subplot(1,2,2); imshow(image);

benchmarks.helpers.plotFrameMatches(mserCorresps, mserReprojFrames,...
  'IsReferenceImage',false);
title(sprintf('MSER Correspondences with %d image (%s dataset).',...
  imageBIdx,dataset.datasetName));

%% Detectors matching score
% For matching score each detector must have defined descriptor
% calculation. Because e.g. VlFeatMSER does not define any descriptor
% extraction we must join it with another class which allows it.

% Define set of tested detector, SIFT detector supports both feature frame
% detection and descriptor extraction.
detectors{1} = siftDetector;
% In this way we define to use SIFT descriptors for the feature frames
% detected by the MSER detector. However because this SIFT implementation
% does not support affine invariant frames, ellipses are converted to
% discs.
detectors{2} = DescriptorAdapter(mserDetector,siftDetector);
% The example detector also supports descriptor calculation however it
% calculates only 3 values for each frame - mean, variance and median of
% the integer disc frame bounding box. This will certainly get worse
% results as SIFT descriptor so let's try to use it on SIFT frames
meanVarMedianDescExtractor = ExampleLocalFeatureExtractor();
detectors{3} = DescriptorAdapter(siftDetector,meanVarMedianDescExtractor);
% As you can see, with DescriptorAdapter we can even overload the default
% detector algorithm for calculating descriptors.

% Define matching benchmark as it is described in IJCV05 article.
% Difference to the repeatability benchmark is only that together with
% features geometry also their descriptors are matched.
matchBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',true,... % Match both geometry and descriptors
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);

% Prealocate the results, same dataset is going to be used
numDetectors = numel(detectors);
matchScore = zeros(numDetectors, numImages);
numMatches = zeros(numDetectors, numImages);

% Test all detectors. As you can see on this example it can be easily
% parallelised simply by using parfor. However it is recommended to disable
% cache auto clearing as can lead to race conditions.
for detectorIdx = 1:numDetectors
  detector = detectors{detectorIdx};
  imageAPath = dataset.getImagePath(1);
  parfor imageIdx = 2:numImages
    imageBPath = dataset.getImagePath(imageIdx);
    tf = dataset.getTransformation(imageIdx);
    [matchScore(detectorIdx,imageIdx) numMatches(detectorIdx,imageIdx)] = ...
      matchBenchmark.testDetector(detector, tf, imageAPath,imageBPath);
  end
end

% Print and plot the results
detectorNames = {'SIFT','MSER + Sim. inv. SIFT desc.',...
  'SIFT frames + Mean/Var/Med desc.'};
figure(4); clf;
subplot(1,2,1);
printScores(detectorNames, matchScore, 'Match Score');
plotScores(detectorNames, dataset, matchScore,'Matching Score');
subplot(1,2,2);
printScores(detectorNames, numMatches, 'Number of matches');
plotScores(detectorNames, dataset, numMatches,'Number of matches');

% Same as with the correspondences we can plot the matches based on feature
% frame descriptors
imageBIdx = 3;
imageBPath = dataset.getImagePath(imageBIdx);
tf = dataset.getTransformation(imageBIdx);

[drop drop siftMatches siftReprojFrames] = ...
  matchBenchmark.testDetector(detectors{1}, tf, imageAPath,imageBPath);
[drop drop mvmMatches mvmReprojFrames] = ...
  matchBenchmark.testDetector(detectors{3}, tf, imageAPath,imageBPath);
    
% And plot the feature frame correspondences
figure(5); clf;
image = imread(imageBPath);
subplot(1,2,1); imshow(image);

benchmarks.helpers.plotFrameMatches(siftMatches, siftReprojFrames,...
  'IsReferenceImage',false);
title(sprintf('SIFT Matches with %d image (%s dataset).',...
  imageBIdx,dataset.datasetName));

subplot(1,2,2); imshow(image);
benchmarks.helpers.plotFrameMatches(mvmMatches, mvmReprojFrames,...
  'IsReferenceImage',false);
title(sprintf('Matches using mean-variance-median descriptor with %d image (%s dataset).',...
  imageBIdx,dataset.datasetName));

%% Helper functions
function printScores(detectorNames, scores, name)
  numDetectors = numel(detectorNames);
  maxNameLen = 0;
  maxNameLen = max(length('Method name'),maxNameLen);
  fprintf(strcat('\nPriting ', name,':\n'));
  formatString = ['%' sprintf('%d',maxNameLen) 's:'];
  fprintf(formatString,'Method name');
  for k = 1:size(scores,2)
    fprintf('\tImg#%02d',k);
  end
  fprintf('\n');
  for k = 1:numDetectors
    fprintf(formatString,detectorNames{k});
    for l = 1:size(scores,2)
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
