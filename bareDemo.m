function bareDemo()
% BAREDEMO Script demonstrating basic interface of the benchmarks.

%% Define Local features detectors

import localFeatures.*;

%detector = randomFeaturesGenerator();
detector = descriptorAdapter(vggMser(),vggAffine());

%% Define dataset

import datasets.*;

dataset = vggAffineDataset('category','graf');

%% Define benchmarks

import benchmarks.*;

repeatabilityTest = repeatabilityBenchmark('CropFrames',false,...
  'NormaliseFrames',false,'OverlapError',0.4);
matchingTest = matchingBenchmark('CropFrames',false,...
  'NormaliseFrames',false,'OverlapError',0.4);
ijcvTest = kristianEvalBenchmark('CommonPart',0,'OverlapError',0.4);

%% Run the benchmarks

numImages = dataset.numImages;

repeatability = zeros(2, numImages);
numCorresp = zeros(2, numImages);

matchingScore = zeros(2, numImages);
numMatches = zeros(2, numImages);

% Get path of the reference image
imageAPath = dataset.getImagePath(1);

for imageIdx = 2:numImages
  imageBPath = dataset.getImagePath(imageIdx);
  tf = dataset.getTransformation(imageIdx);
  
  % Run the repeatability and matching benchmark
  [repeatability(1,imageIdx) numCorresp(1,imageIdx)] = ...
    repeatabilityTest.testDetector(detector, tf, imageAPath,imageBPath);
  [matchingScore(1,imageIdx) numMatches(1,imageIdx)] = ...
    matchingTest.testDetector(detector, tf, imageAPath,imageBPath);

  % Run the IJCV test for comparison
  [repeatability(2,imageIdx) numCorresp(2,imageIdx) ...
    matchingScore(2,imageIdx) numMatches(2,imageIdx)] = ...
    ijcvTest.testDetector(detector, tf, imageAPath,imageBPath);
end



%% Show scores

scoreLineNames = {'VLFeat','IJCV'};

printScores(repeatability, scoreLineNames ,'Repeatability');
printScores(numCorresp, scoreLineNames, 'Number of correspondences');
printScores(matchingScore, scoreLineNames, 'Match Score');
printScores(numMatches, scoreLineNames, 'Num of matches');


%% Helper functions

function printScores(scores, scoreLineNames, name)
  % PRINTSCORES
  numScores = numel(scoreLineNames);

  maxNameLen = 0;
  for k = 1:numScores
    maxNameLen = max(maxNameLen,length(scoreLineNames{k}));
  end

  maxNameLen = max(length('Method name'),maxNameLen);
  fprintf(strcat('\nPriting ', name,':\n'));
  formatString = ['%' sprintf('%d',maxNameLen) 's:'];

  fprintf(formatString,'Method name');
  for k = 1:size(scores,2)
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
