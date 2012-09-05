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

%% Define dataset

import datasets.*;

categories = vggAffineDataset.allCategories;

for category=categories
  fprintf('\n######## TESTING DATASET %s #######\n',category{:});
  dataset = vggAffineDataset('category',category{:});

  %% Run the new benchmarks in parallel

  numDetectors = numel(detectors);
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

  resultsDir = 'ijcc05_res';
  category = dataset.category;

  figure(1); clf;
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

  set(gcf,'PaperPositionMode','auto')
  set(gcf,'PaperType','A4');
  set(gcf, 'Position', [0, 0, 900,700]);
  print(gcf,fullfile(resultsDir, ['fig13_rm_' dataset.category '.eps']),'-depsc');

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

  resultsDir = 'ijcc05_res';
  category = dataset.category;

  figure(1); clf;
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

  set(gcf,'PaperPositionMode','auto')
  set(gcf,'PaperType','A4');
  set(gcf, 'Position', [0, 0, 900,700]);
  print(gcf,fullfile(resultsDir, ['fig13_rm_' dataset.category '.eps']),'-depsc');


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
    save([dir name],'scores');
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

end
