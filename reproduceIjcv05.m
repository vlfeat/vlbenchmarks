function reproduceIjcv05(varargin)
% REPRODUCEIJCV05 Reproduce results from the IJCV05 article
%   REPRODUCEIJCV05('OptionName',OptionValue) computes results presented 
%   in [1] and stores them as graphs and data files (*.mat + *.csv).
%
%   This function does not reproduce figures which require tuning of
%   detector parameters (21c, 22a and 22b) as some of the available
%   binaries does not allow to affect a number of detected frames.
%
%   Supported Options:
%
%   ResultsDir:: 'ijcv05_res'
%     Path where to store computed data.
%
%   UseIjcvOriginalBenchmark:: true
%     Compute the results with the original IJCV05 code. When true, the
%     test takes several minutes.
%
%   REFERENCES
%   [1] K. Mikolajczyk, T. Tuytelaars, C. Schmid, A. Zisserman,
%       J. Matas, F. Schaffalitzky, T. Kadir, and L. Van Gool. A
%       comparison of affine region detectors. IJCV, 1(65):43–72, 2005.

% AUTORIGHTS

import datasets.*;
import localFeatures.*;
import benchmarks.*;

opts.resultsDir = 'ijcv05_res'; % Directory to store generated files
opts.useIjcvOriginalBenchmark = true; % Set false if you want to skip KM benchm.
opts = helpers.vl_argparse(opts, varargin);

%% Define Local features extractors
% Create local features extractor such that each of them uses the same
% algorithm and parameters for computing SIFT descriptors.
descDet = VggAffine('CropFrames',true,'Magnification',3); % Descriptor calc.
detectors{1} = DescriptorAdapter(...
  VggAffine('Detector','haraff','Threshold',1000), descDet);
detectors{2} = DescriptorAdapter(...
  VggAffine('Detector','hesaff','Threshold',500), descDet);
detectors{3} = DescriptorAdapter(VggMser('es',1),descDet);
detectors{4} = DescriptorAdapter(Ibr('ScaleFactor',1),descDet);
detectors{5} = DescriptorAdapter(Ebr(),descDet);

detNames = {'Harris-Affine','Hessian-Affine','MSER','IBR','EBR'};
numDetectors = numel(detectors);


%% Define benchmarks
repBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);
matchBenchmark = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',true,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4);

kmBenchmark = IjcvOriginalBenchmark('CommonPart',1);

%% Define Figure
fig = figure('Visible','off');
detColorMap = hsv(numDetectors);

%% Repeatability vs. overlap error
fprintf('\n######## REPEATABILITY VS. OVERLAP ERR (Fig. 21a) #######\n');

dataset = VggAffineDataset('category','graf');
overlapErrValues = 0.1:0.1:0.6;
imageBIdx = 4;

oeScores = zeros(numDetectors,numel(overlapErrValues));
confFig(fig);
for oei = 1:numel(overlapErrValues)
  rBenchm = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',overlapErrValues(oei));

  imageAPath = dataset.getImagePath(1);
  imageBPath = dataset.getImagePath(imageBIdx);
  H = dataset.getTransformation(imageBIdx);
  parfor detectorIdx = 1:numDetectors
    detector = detectors{detectorIdx};
    [oeScores(detectorIdx,oei) tmp] = ...
      rBenchm.testDetector(detector, H, imageAPath,imageBPath);
  end
end

saveResults(oeScores, fullfile(opts.resultsDir,'rep_vs_overlap'));
subplot(2,2,1); 
plot(overlapErrValues.*100,oeScores.*100,'+-'); grid on;
xlabel('Overlap error %'); ylabel('Repeatability %');
axis([5 65 0 100]);
legend(detNames,'Location','NorthWest');

%% Repeatability vs. normalised region size
fprintf('\n######## REPEATABILITY VS. NORM. REG. SIZE (Fig. 21b) #######\n');

normRegSizes = [15 30 50 75 90 110];
nrsScores = zeros(numDetectors,numel(normRegSizes));

for nrsi = 1:numel(normRegSizes)
  rBenchm = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',true,...
  'OverlapError',0.4,...
  'NormalisedScale',normRegSizes(nrsi));
  imageAPath = dataset.getImagePath(1);
  imageBPath = dataset.getImagePath(imageBIdx);
  H = dataset.getTransformation(imageBIdx);
  parfor detectorIdx = 1:numDetectors
    detector = detectors{detectorIdx};
    nrsScores(detectorIdx,nrsi) = ...
      rBenchm.testDetector(detector, H, imageAPath,imageBPath);
  end
end
saveResults(oeScores, fullfile(opts.resultsDir,'rep_vs_norm_reg_size'));
subplot(2,2,2); 
plot(normRegSizes,nrsScores.*100,'+-'); grid on;
xlabel('Normalised region size'); ylabel('Repeatability %');
axis([10 120 0 100]);
legend(detNames,'Location','SouthEast');


%% Repeatability vs. region sizes
fprintf('\n######## REPEATABILITY VS. REGION SIZE (Fig. 21d) #######\n');

regSizeBenchm = RepeatabilityBenchmark(...
  'MatchFramesGeometry',true,...
  'MatchFramesDescriptors',false,...
  'WarpMethod','km',...
  'CropFrames',true,...
  'NormaliseFrames',false,...
  'OverlapError',0.4,...
  'Magnification',1);

numBins = 10;
imageBIdx = 4;
dataset = VggAffineDataset('category','graf');

rsScores = zeros(numDetectors,numBins);
binAvgs = zeros(numDetectors,numBins); % Centres of frame scales bins
numFramesInBin = zeros(numDetectors,numBins);
framesA = cell(numDetectors,1);
framesB = cell(numDetectors,1);

imageAPath = dataset.getImagePath(1);
imageBPath = dataset.getImagePath(imageBIdx);
imageASize = helpers.imageSize(imageAPath);
imageBSize = helpers.imageSize(imageBPath);
H = dataset.getTransformation(imageBIdx);

% Detect the frames
parfor di = 1:numDetectors
  detector = detectors{di};
  framesA{di} = detector.extractFeatures(imageAPath);
  framesB{di} = detector.extractFeatures(imageBPath);
end

subplot(2,2,4); hold on;

% Process the results
for di = 1:numDetectors
  % Divide the frames based on scales into equaly distributed ones
  scalesA = localFeatures.helpers.getFrameScale(framesA{di});
  binA = ceil(numBins * tiedrank(scalesA) / length(scalesA));
  for nrsi = 1:numBins
    sFramesA = framesA{di}(:,binA == nrsi);
    sFramesB = framesB{di};
    numFramesInBin(di,nrsi) = size(sFramesA,2);
    binAvgs(di,nrsi) = mean(scalesA(binA == nrsi));
    rsScores(di,nrsi)= rsScores(di,nrsi) +...
      regSizeBenchm.testFeatures(H, imageASize, imageBSize, ...
        sFramesA,sFramesB);
  end
  plot(binAvgs(di,:),rsScores(di,:).*100,'+-',...
    'Color',detColorMap(di,:));
end

saveResults(rsScores, fullfile(opts.resultsDir,'rep_vs_reg_size'));
grid on;
xlabel('Region size'); ylabel('Repeatability %');
axis([0 max(binAvgs(:)) 0 100]);
legend(detNames,'Location','SouthEast');

% Plot the number of frames per bin for each detector
subplot(2,2,3);
bar(mean(numFramesInBin,2));
set(gca,'XTick',1:numDetectors)
set(gca,'XTickLabel',detNames);
ylabel('Number of frames per region size bin');

print(fig,fullfile(opts.resultsDir, 'fig_rep_graf.eps'),'-depsc');

%% Matching vs. magnification factor
fprintf('\n######## MATCHING SCORE VS. REGION MAGNIF. (Fig. 22c) #######\n');

dataset = VggAffineDataset('category','graf');
imageBIdx = 4;
magFactors = 1:5;

magnifScores = zeros(numDetectors,numel(magFactors));
confFig(fig);

for mf = 1:numel(magFactors)
  magFactor = magFactors(mf);
  imageAPath = dataset.getImagePath(1);
  imageBPath = dataset.getImagePath(imageBIdx);
  H = dataset.getTransformation(imageBIdx);
  parfor detectorIdx = 1:numDetectors
    descrExtr = VggAffine('Magnification',magFactor);
    detector = DescriptorAdapter(detectors{detectorIdx},descrExtr);
    magnifScores(detectorIdx,mf) = ...
      matchBenchmark.testDetector(detector, H, imageAPath,imageBPath);
  end
end
saveResults(magnifScores, fullfile(opts.resultsDir,'matching_vs_mag'));
subplot(2,2,4); 
plot(magFactors,magnifScores'.*100,'+-'); grid on;
xlabel('Magnification factor'); ylabel('Matching %');
axis([0.5 5.5 0 100]);
legend(detNames,'Location','NorthEast');

print(fig,fullfile(opts.resultsDir, 'fig_matching_graf.eps'),'-depsc');

%% Regions sizes histograms
fprintf('\n######## REGION SIZE HISTOGRAMS (Fig. 10) #######\n');
if (0)
dataset = VggAffineDataset('category','graf');
refImgPath = dataset.getImagePath(1);

numFrames = zeros(numDetectors,1);
runTime = zeros(numDetectors,1);
detFrames = cell(1,numDetectors);

confFig(fig);

% Detect the frames
parfor di = 1:numDetectors
  % Disable caching in order to force computation
  detectors{di}.disableCaching();
  startTime = tic;
  detFrames{di} = detectors{di}.extractFeatures(refImgPath);
  runTime(di) = toc(startTime);
  detectors{di}.enableCaching();
end

% Process the results
for di = 1:numDetectors
  numFrames(di) = size(detFrames{di},2);
  scales = getFrameScale(detFrames{di});
  subplot(2,3,di);
  scalesHist = hist(scales,0:100);
  bar(scalesHist);
  axis([0 100 0 ceil(max(scalesHist)/10)*10]); 
  grid on;
  title(detNames{di});
  xlabel('Average region size');
  ylabel('Number of detected regions');
end

saveResults(runTime, fullfile(opts.resultsDir,'det_run_time_graf_img1ppm'));
saveResults(numFrames, fullfile(opts.resultsDir,'det_num_frames_graf_img1ppm'));

print(fig,fullfile(opts.resultsDir, 'fig_hist_graf.eps'),'-depsc');
end
%% Repeatability and Matching scores
fprintf('\n######## REPEATABILITY AND MATCHING SCORES (Fig. 13-20) #######\n');

datasetNum = 1;
categories = VggAffineDataset.allCategories;
for category=categories
  fprintf('\n######## TESTING DATASET %s #######\n',category{:});
  dataset = VggAffineDataset('category',category{:});

  %% Run the new benchmarks in parallel
  numImages = dataset.numImages;

  repeatability = zeros(numDetectors, numImages);
  numCorresp = zeros(numDetectors, numImages);

  matchingScore = zeros(numDetectors, numImages);
  numMatches = zeros(numDetectors, numImages);

  % Test all detectors
  for di = 1:numDetectors
    detector = detectors{di};
    imageAPath = dataset.getImagePath(1);
    parfor imageIdx = 2:numImages
      imageBPath = dataset.getImagePath(imageIdx);
      H = dataset.getTransformation(imageIdx);
      [repeatability(di,imageIdx) numCorresp(di,imageIdx)] = ...
        repBenchmark.testDetector(detector, H, imageAPath,imageBPath);
      [matchingScore(di,imageIdx) numMatches(di,imageIdx)] = ...
        matchBenchmark.testDetector(detector, H, imageAPath,imageBPath);
    end
  end

  %% Show scores
  confFig(fig);
  titleText = ['Detectors Repeatability [%%] (',category{:},')'];
  printScores(repeatability.*100, detNames, titleText,...
    fullfile(opts.resultsDir,[category{:} '_rep']));
  subplot(2,2,1); plotScores(repeatability.*100, detNames, dataset,...
    titleText);

  printScores(repeatability.*100, detNames, titleText,...
    fullfile(opts.resultsDir,[category{:} '_rep']));
  subplot(2,2,1); plotScores(repeatability.*100, detNames,...
    dataset, titleText);

  titleText = ['Detectors Num. Correspondences (',category{:},')'];
  printScores(numCorresp, detNames, titleText,...
    fullfile(opts.resultsDir,[category{:} '_ncorresp']));
  subplot(2,2,2); plotScores(numCorresp, detNames, dataset, titleText);

  titleText = ['Detectors Matching Score [%%] (',category{:},')'];
  printScores(matchingScore.*100, detNames, titleText,...
    fullfile(opts.resultsDir,[category{:} '_matching']));
  subplot(2,2,3); plotScores(matchingScore.*100, detNames, dataset,...
    titleText);

  titleText = ['Detectors Num. Matches (',category{:},')'];
  printScores(numMatches, detNames, titleText,...
    fullfile(opts.resultsDir,[category{:} '_nmatches']));
  subplot(2,2,4); plotScores(numMatches, detNames, dataset, titleText);

  print(fig,fullfile(opts.resultsDir, ['fig' num2str(datasetNum) '_rm_' ...
    dataset.category '.eps']),'-depsc');

  %% For comparison, run IJCV05 original Benchmark
  if opts.useIjcvOriginalBenchmark
    % Test all detectors
    for di = 1:numDetectors
      detector = detectors{di};
      imageAPath = dataset.getImagePath(1);
      parfor imageIdx = 2:numImages
        imageBPath = dataset.getImagePath(imageIdx);
        H = dataset.getTransformation(imageIdx);
        % Repeatability must be computed separately in order to be able to
        % compare it with the previous results as the number of frames when
        % computed with and without descriptors differs.
        [repeatability(di,imageIdx) numCorresp(di,imageIdx)] = ...
          kmBenchmark.testDetector(detector, H, imageAPath,imageBPath);
        [tmp tmp2 matchingScore(di,imageIdx) numMatches(di,imageIdx)] = ...
          kmBenchmark.testDetector(detector, H, imageAPath,imageBPath);
      end
    end

    confFig(fig);

    titleText = 'Detectors Repeatability [%%]';
    printScores(repeatability.*100, detNames, titleText,...
      fullfile(opts.resultsDir,['km_' category{:} '_rep']));
    subplot(2,2,1); plotScores(repeatability.*100, detNames, dataset,...
      titleText);

    titleText = ['KM Detectors Num. Correspondences (',category{:},')'];
    printScores(numCorresp, detNames, titleText,...
      fullfile(opts.resultsDir,['km_' category{:} '_ncorresp']));
    subplot(2,2,2); plotScores(numCorresp, detNames, dataset, titleText);

    titleText = ['KM Detectors Matching Score [%%] (',category{:},')'];
    printScores(matchingScore.*100, detNames, titleText,...
      fullfile(opts.resultsDir,['km_' category{:} '_matching']));
    subplot(2,2,3); plotScores(matchingScore.*100, detNames, dataset, ...
      titleText);

    titleText = ['KM Detectors Num. Matches (',category{:},')'];
    printScores(numMatches, detNames, titleText,...
      fullfile(opts.resultsDir,['km_' category{:} '_nmatches']));
    subplot(2,2,4); plotScores(numMatches, detNames, dataset, titleText);

    print(fig,fullfile(opts.resultsDir, ['km_fig' num2str(datasetNum) '_rm_' ...
      dataset.category '.eps']),'-depsc');
  end

  datasetNum = datasetNum + 1;
end

%% Helper functions
function printScores(scores, scoreLineNames, name, fileName)
  numScores = size(scores,1);

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
    saveResults(scores,fileName);
  end
end

function saveResults(scores, fileName)
  [dir name] = fileparts(fileName);
  vl_xmkdir(dir);
  save(fullfile(dir,name),'scores');
  csvwrite(fullfile(dir, [name '.csv']), scores);
end

function plotScores(scores, detNames, dataset, titleText)
  % PLOTSCORES
  import helpres.*;
  titleText = sprintf(titleText);
  
  xLabel = dataset.imageNamesLabel;
  xVals = dataset.imageNames;
  plot(xVals,scores(:,2:6)','+-','linewidth', 1) ; hold on ;
  ylabel(titleText) ;
  xlabel(xLabel);
  title(titleText);

  maxScore = ceil(max([max(max(scores)) 100])/10)*10;

  legend(detNames,'Location','NorthEast');
  grid on ;
  axis([min(xVals)*0.9 max(xVals)*1.05 0 maxScore]);
end

function confFig(fig)
  clf(fig);
  set(fig,'PaperPositionMode','auto')
  set(fig,'PaperType','A4');
  set(fig, 'Position', [0, 0, 900,700]);
end

end
