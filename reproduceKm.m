function reproduceKm()
% BENCHMARKDEMO Script demonstrating how to run the benchmarks for
%   different algorithms.
%

%% Define Local features detectors

import localFeatures.*;

descDet = vggAffine();

detectors{1} = vggAffine('Detector', 'haraff','Threshold',1000);
detectors{2} = vggAffine('Detector', 'hesaff','Threshold',500);
detectors{3} = descriptorAdapter(vggMser('es',2),descDet);
detectors{4} = descriptorAdapter(ibr('ScaleFactor',1),descDet);
detectors{5} = descriptorAdapter(ebr(),descDet);

detNames = {'Harris-Affine','Hessian-Affine','MSER','IBR','EBR'};
numDetectors = numel(detectors);


%% Define benchmarks

import benchmarks.*;

repBenchmark = repeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);
matchBenchmark = repeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',true,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);

kmBenchmark = kristianEvalBenchmark('CommonPart',1);

%% Define Figure
fig = figure('Visible','off');

%% Define dataset

import datasets.*;

categories = vggAffineDataset.allCategories;
datasetNum = 1;


%% Regions sizes histograms
numFrames = cell(1,numDetectors);
runTime = cell(1,numDetectors);
dataset = vggAffineDataset('category','graf');

confFig(fig);

for di = 1:numDetectors
  refImgPath = dataset.getImagePath(1);
  % Removed cached data in order to force compuation
  detectors{di}.disableCaching();
  startTime = tic;
  frames = detectors{di}.extractFeatures(refImgPath);
  runTime{di} = toc(startTime);
  detectors{di}.enableCaching();
  numFrames{di} = size(frames,2);
  scales = getFrameScale(frames);
  subplot(2,3,di);
  scalesHist = hist(scales,0:100);
  bar(scalesHist);
  axis([0 100 0 ceil(max(scalesHist)/10)*10]); 
  grid on;
  title(detNames{di});
  xlabel('Average region size');
  ylabel('Number of detected regions');
end

print(fig,fullfile(resultsDir, ['fig' num2str(datasetNum) '_rm_' ...
  dataset.category '.eps']),'-depsc');

%% Repeatability / Matching scores

for category=categories
  fprintf('\n######## TESTING DATASET %s #######\n',category{:});
  dataset = vggAffineDataset('category',category{:});

  %% Run the new benchmarks in parallel
  numImages = dataset.numImages;

  repeatability = zeros(numDetectors, numImages);
  numCorresp = zeros(numDetectors, numImages);

  matchingScore = zeros(numDetectors, numImages);
  numMatches = zeros(numDetectors, numImages);

  % Test all detectors
  for detectorIdx = 1:numDetectors
    detector = detectors{detectorIdx};
    imageAPath = dataset.getImagePath(1);
    parfor imageIdx = 2:numImages
      imageBPath = dataset.getImagePath(imageIdx);
      H = dataset.getTransformation(imageIdx);
      [repeatability(detectorIdx,imageIdx) numCorresp(detectorIdx,imageIdx)] = ...
        repBenchmark.testDetector(detector, H, imageAPath,imageBPath);
      [matchingScore(detectorIdx,imageIdx) numMatches(detectorIdx,imageIdx)] = ...
        matchBenchmark.testDetector(detector, H, imageAPath,imageBPath);
    end
  end



  %% Show scores

  resultsDir = 'ijcv05_res';
  category = dataset.category;

  confFig(fig);

  titleText = 'Detectors Repeatability [%%]';
  printScores(repeatability.*100, detNames, titleText,fullfile(resultsDir,[category '_rep']));
  subplot(2,2,1); plotScores(repeatability.*100, detNames, dataset, titleText);

  titleText = 'Detectors Num. Correspondences';
  printScores(numCorresp, detNames, titleText,fullfile(resultsDir,[category '_ncorresp']));
  subplot(2,2,2); plotScores(numCorresp, detNames, dataset, titleText);

  titleText = 'Detectors Matching Score [%%]';
  printScores(matchingScore.*100, detNames, titleText,fullfile(resultsDir,[category '_matching']));
  subplot(2,2,3); plotScores(matchingScore.*100, detNames, dataset, titleText);

  titleText = 'Detectors Num. Matches';
  printScores(numMatches, detNames, titleText,fullfile(resultsDir,[category '_nmatches']));
  subplot(2,2,4); plotScores(numMatches, detNames, dataset, titleText);

  print(fig,fullfile(resultsDir, ['fig' num2str(datasetNum) '_rm_' ...
    dataset.category '.eps']),'-depsc');

  %% For comparison, run KM Benchmark

  % Test all detectors
  for detectorIdx = 1:numDetectors
    detector = detectors{detectorIdx};
    imageAPath = dataset.getImagePath(1);
    parfor imageIdx = 2:numImages
      imageBPath = dataset.getImagePath(imageIdx);
      H = dataset.getTransformation(imageIdx);
      [repeatability(detectorIdx,imageIdx) numCorresp(detectorIdx,imageIdx)] = ...
        kmBenchmark.testDetector(detector, H, imageAPath,imageBPath);
      [tmp tmp2 matchingScore(detectorIdx,imageIdx) numMatches(detectorIdx,imageIdx)] = ...
        kmBenchmark.testDetector(detector, H, imageAPath,imageBPath);
    end
  end

  %%

  resultsDir = 'ijcv05_res';
  category = dataset.category;

  confFig(fig);

  titleText = 'Detectors Repeatability [%%]';
  printScores(repeatability.*100, detNames, titleText,fullfile(resultsDir,['km_' category '_rep']));
  subplot(2,2,1); plotScores(repeatability.*100, detNames, dataset, titleText);

  titleText = 'Detectors Num. Correspondences';
  printScores(numCorresp, detNames, titleText,fullfile(resultsDir,['km_' category '_ncorresp']));
  subplot(2,2,2); plotScores(numCorresp, detNames, dataset, titleText);

  titleText = 'Detectors Matching Score [%%]';
  printScores(matchingScore.*100, detNames, titleText,fullfile(resultsDir,['km_' category '_matching']));
  subplot(2,2,3); plotScores(matchingScore.*100, detNames, dataset, titleText);

  titleText = 'Detectors Num. Matches';
  printScores(numMatches, detNames, titleText,fullfile(resultsDir,['km_' category '_nmatches']));
  subplot(2,2,4); plotScores(numMatches, detNames, dataset, titleText);

  print(fig,fullfile(resultsDir, ['fig' num2str(datasetNum) '_rm_' ...
    dataset.category '.eps']),'-depsc');

  datasetNum = datasetNum + 1;
end


%% Helper functions

function printScores(scores, scoreLineNames, name, fileName)
  % PRINTSCORES
  numScores = numel(scoreLineNames);

  maxNameLen = 0;
  for k = 1:numScores
    maxNameLen = max(maxNameLen,length(scoreLineNames{k}));
  end

  maxNameLen = max(length('Method name'),maxNameLen);
  fprintf(['\n', name,':\n']);
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
  
  if exist('fileName','var');
    [dir name] = fileparts(fileName);
    vl_xmkdir(dir);
    save(fullfile(dir,name),'scores');
    csvwrite(fullfile(dir, [name '.csv']), scores);
  end
end

function plotScores(scores, detNames, dataset, titleText)
  % PLOTSCORES
  import helpres.*;
  titleText = sprintf(titleText);
  
  xLabel = dataset.imageNamesLabel;
  xVals = dataset.imageNames;
  plot(xVals,scores(:,2:6)','linewidth', 3) ; hold on ;
  ylabel(titleText) ;
  xlabel(xLabel);
  title(titleText);

  maxScore = max([max(max(scores)) 100]);

  legendLocation = 'NorthEast';

  legendStr = cell(1,numel(detNames));
  for m = 1:numel(detNames) 
    legendStr{m} = detNames{m}; 
  end
  legend(legendStr,'Location',legendLocation);
  grid on ;
  axis([min(xVals)*0.9 max(xVals)*1.1 0 maxScore]);
end

function scale = getFrameScale(frames)
  det = prod(frames([3 5],:)) - frames(4,:).^2;
  scale = sqrt(sqrt(det));
end

function confFigure(fig)
  clf(fig);
  set(fig,'PaperPositionMode','auto')
  set(fig,'PaperType','A4');
  set(fig, 'Position', [0, 0, 900,700]);
end

end
