function bareDemo()
% BAREDEMO Script demonstrating basic interface of the benchmarks.

% TODO show the matches
% TODO plot the score.
% TODO caching

%% Define Local features detectors
import localFeatures.*;
detectors{1} = RandomFeaturesGenerator();
detectors{1} = localFeatures.ExampleLocalFeatureExtractor(...
  'UseMean',true,...
  'UseVariance',true,...
  'UseMedian',true); 
detectors{1} = DescriptorAdapter(VlFeatMser(),VlFeatSift());
%detectors{3} = VlFeatSift();

%% Define dataset
import datasets.*;
dataset = VggAffineDataset('category','graf');
numImages = dataset.NumImages;

%% Define benchmarks
import benchmarks.*;
repeatabilityTest = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);
matchingTest = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',true,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);
ijcvTest = IjcvOriginalBenchmark('CommonPart',1,'OverlapError',0.4);

%% Compare the results of VlFeat repeatability and the IJCV05 repeatability

repeatability = zeros(numel(detectors), numImages);
numCorresp = zeros(numel(detectors), numImages);
matchingScore = zeros(numel(detectors), numImages);
numMatches = zeros(numel(detectors), numImages);

% Get path of the reference image
imageAPath = dataset.getImagePath(1);

for detIdx = 1:numel(detectors)
  for imageIdx = 2:numImages
    imageBPath = dataset.getImagePath(imageIdx);
    tf = dataset.getTransformation(imageIdx);

    % Run the repeatability and matching benchmark
    [repeatability(detIdx,imageIdx) numCorresp(detIdx,imageIdx)] = ...
      repeatabilityTest.testDetector(detectors{detIdx}, tf, imageAPath,imageBPath);
    [matchingScore(detIdx,imageIdx) numMatches(detIdx,imageIdx)] = ...
      matchingTest.testDetector(detectors{detIdx}, tf, imageAPath,imageBPath);
  end
end


%% Show scores

scoreLineNames = {'VLFB res.','IJCV res.','asdf'};

printScores(repeatability, scoreLineNames ,'Repeatability');
printScores(numCorresp, scoreLineNames, 'Number of correspondences');
printScores(matchingScore, scoreLineNames, 'Match Score');
printScores(numMatches, scoreLineNames, 'Num of matches');


%% Helper functions
function printScores(scores, scoreLineNames, name)
  numScores = numel(scoreLineNames);
  maxNameLen = 0;
  for k = 1:numScores
    maxNameLen = max(maxNameLen,length(scoreLineNames{k}));
  end
  maxNameLen = max(length('Method name'),maxNameLen);
  fprintf(['\n',name,':\n']);
  formatString = ['%' sprintf('%d',maxNameLen) 's:'];
  fprintf(formatString,'Method name');
  for k = 2:size(scores,2)
    fprintf('\tImg#%02d',k);
  end
  fprintf('\n');
  for k = 1:numScores
    fprintf(formatString,scoreLineNames{k});
    for l = 2:size(scores,2)
      fprintf('\t%6s',sprintf('%.2f',scores(k,l)));
    end
    fprintf('\n');
  end
end

end
