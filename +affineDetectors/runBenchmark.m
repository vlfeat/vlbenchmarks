function runBenchmark(detectors,dataset,varargin)
% RUNBENCHMARK Run the affine co-variant detector benchmark
%   runBenchmark(Detectors,Dataset,'Option','OptionValue',...) runs
%   a suite of detectors on a given dataset. The benchmark should
%   reproduce the benchmark available at:
%   http://www.robots.ox.ac.uk/~vgg/research/affine/evaluation.html
%
%   Detectors: A cell array of various detectors to run on. Each detector has to
%   implement the affineDetectors.genericDetector interface
%
%   Dataset: An object that implements the class affineDetector.genericDataset
%
%   Options:
%
%   ShowQualitative :: [true]
%     Set to true to output qualitative results with ellipses for each detector
%
%   SaveResult      :: [true]
%     Set to true to enable saving the output figure and numbers into a directory
%
%   SaveDir         :: ['./savedResults/']
%     Directory where to save the output of the evaluation.
%
%   OverlapError    :: [0.4]
%     Two ellipses are deemed to correspond when their overlap area error
%     is smaller than OverlapError.
%
%   VerifyKristian  :: [false]
%     Also runs the benchmark available at:
%     http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz
%     and plots the results for comparison

import affineDetectors.*;

% -------- create options ------------------------
opts.showQualitative = true;
opts.saveResult = true;
opts.saveDir = './savedResults/';
opts.verifyKristian = false;
opts.overlapError = 0.4;
opts = commonFns.vl_argparse(opts,varargin);

% -------- Load the dataset ----------------------------------------------------
assert(isa(dataset,'affineDetectors.genericDataset'),...
    'dataset not an instance of generic dataset\n');
numImages = dataset.numImages;
images = cell(1,numImages);
imagePaths = cell(1,numImages);
for i=1:numImages
  imagePaths{i} = dataset.getImagePath(i);
  images{i} = imread(imagePaths{i});
  tfs{i} = dataset.getTransformation(i);
end

% -------- Compute each detectors output and store the evaluation --------------
numDetectors = numel(detectors);
repeatibilityScore = zeros(numDetectors,numImages); repeatibilityScore(:,1)=1;
numOfCorresp = zeros(numDetectors,numImages);
if(opts.verifyKristian)
  repScoreKristian  = zeros(numDetectors,numImages);
  numOfCorrespKristian  = zeros(numDetectors,numImages);
end

if opts.showQualitative
  figure(1); clf;
  plotDataset(images);
end

% Clear all the figures
if opts.showQualitative
  for i = 2:numImages, figure(i); clf; end
end

fprintf('Running evaluation on %d detectors:\n',numDetectors);

for i = 1:numel(detectors)
  assert(isa(detectors{i},'affineDetectors.genericDetector'),...
         'Detector not an instance of genericDetector\n');
  fprintf('Detector #%02d: %s\n',i,detectors{i}.getName());
end

for iDetector = 1:numel(detectors)
  frames = cell(1,numImages);
  curDetector = detectors{iDetector};
  fprintf('\nComputing affine covariant regions for method #%02d: %s\n\n', ...
          iDetector, curDetector.getName());

  if(~curDetector.isOk)
    fprintf('Detector: %s is not working, message: %s\n',curDetector.getName(),...
            curDetector.errMsg);
    repeatibilityScore(iDetector,:) = 0;
    continue;
  end

  for i = 1:numImages
    fprintf('Computing regions for image: %02d/%02d ...',i,numImages);
    frames{i} = curDetector.detectPoints(images{i});
    fprintf(' (%d regions detected)\r',size(frames{i},2));
  end

  fprintf('\n');

  for i=2:numImages
    fprintf('Evaluating regions for image: %02d/%02d ...\n',i,numImages);
    [framesA,framesB,framesA_,framesB_] = ...
        helpers.cropFramesToOverlapRegion(frames{1},frames{i},...
        tfs{i},images{1},images{i});


    frameMatches = matchEllipses(framesB_, framesA);
    [bestMatches,matchIdxs] = ...
        findOneToOneMatches(frameMatches,framesA,framesB_, opts.overlapError);
    repeatibilityScore(iDetector,i) = ...
        sum(bestMatches) / min(size(framesA,2), size(framesB,2));
    numOfCorresp(iDetector,i) = sum(bestMatches);

    if opts.showQualitative
      plotFrames(framesA,framesB,framesA_,framesB_,iDetector,i,numDetectors,...
                images{1},images{i},curDetector.getName(),matchIdxs);
    end

  end

  if (opts.verifyKristian)
    fprintf('Running kristians benchmark code for verifying benchmark results:\n');
    [repScoreKristian(iDetector,:), ...
     numOfCorrespKristian(iDetector,:)] = runKristianEval(frames,imagePaths,...
                                                         images,tfs, opts.overlapError);
  end

end

repeatibilityScore = repeatibilityScore * 100;
fprintf('\n------ Evaluation completed ---------\n');

% ----------------- Plot the evaluation scores ---------------------------------
plotScores(numImages+1,'detectorEval', repeatibilityScore, ...
           'Detector repeatibility vs. image index', ...
           'Image #','Repeatibility. %',detectors, opts, 1);
plotScores(numImages+2,'numCorrespond', numOfCorresp, ...
           'Detector num. of correspondences vs. image index', ...
           'Image #','#correspondences',detectors, opts, 2);
if(opts.verifyKristian)
    plotScores(numImages+3,'KM_repeatability', repScoreKristian, ...
           'KM Detector repeatibility vs. image index', ...
           'Image #','Repeatibility. %',detectors, opts, 1);
    plotScores(numImages+4,'KM_numCorrespond', numOfCorrespKristian, ...
           'KM Detector num. of correspondences vs. image index', ...
           'Image #','#correspondences',detectors, opts, 2);
end
       
% -------- Print out and save the scores --------------------
detNames = printScores(opts,detectors,repeatibilityScore,'detectorEval.txt', 'repeatability scores');
printScores(opts,detectors,numOfCorresp,'numCorresp.txt', 'num. of correspondences');
if(opts.verifyKristian)
  fprintf('\nOutput of Kristians benchmark:\n');
  printScores(opts,detectors,repScoreKristian,'detectorEvalKristianRepScore.txt', 'KM repeatability scores');
  printScores(opts,detectors,numOfCorrespKristian,'detectorEvalKristianCorrNum.txt', 'KM num. of correspondences');
end

if(opts.saveResult)
  matFile = fullfile(opts.saveDir,'detectorEval.mat');
  save(matFile,'detNames','repeatibilityScore');
  fprintf('\nScores saved to: %s\n',matFile);
end

% -------- Output which detectors didn't work ------
for i = 1:numel(detectors),
  if ~detectors{i}.isOk,
    fprintf('Detector %s failed because: %s\n',detectors{i}.getName(),...
            detectors{i}.errMsg);
  end
end
end

function detNames = printScores(opts,detectors,repeatibilityScore,outFile, name);

numDetectors = numel(detectors);

if(opts.saveResult)
  fH = fopen(fullfile(opts.saveDir,outFile),'w');
  fidOut = [1 fH];
else
  fidOut = 1;
end

detNames = cell(1,numel(detectors));
maxNameLen = 0;
for i = 1:numDetectors
  detNames{i} = detectors{i}.getName();
  maxNameLen = max(maxNameLen,length(detNames{i}));
end

maxNameLen = max(length('Method name'),maxNameLen);
myprintf(fidOut,strcat('\nPriting ', name,':\n'));
formatString = ['%' sprintf('%d',maxNameLen) 's:'];

myprintf(fidOut,formatString,'Method name');
for i = 1:size(repeatibilityScore,2)
 myprintf(fidOut,'  Img#%02d',i);
end
myprintf(fidOut,'\n');

for i = 1:numDetectors
  myprintf(fidOut,formatString,detNames{i});
  for j = 1:size(repeatibilityScore,2)
    myprintf(fidOut,'  %6s',sprintf('%.2f',repeatibilityScore(i,j)));
  end
  myprintf(fidOut,'\n');
end

if(opts.saveResult)
  fclose(fH);
end
end

function plotScores(figureNum, name, score, title_text, x_label, y_label, detectors, opts, xstart)
    if isempty(xstart)
        xstart = 1;
    end
    figure(figureNum) ; clf ;
    xend = size(score,2);
    plot(xstart:xend,score(:,xstart:xend)','linewidth', 3) ; hold on ;
    ylabel(y_label) ;
    xlabel(x_label);
    title(title_text);
    %ylim([0 100]);
    set(gca,'xtick',[1:size(score,2)]);

    legendStr = cell(1,numel(detectors));
    for i = 1:numel(detectors), legendStr{i} = detectors{i}.getName(); end
    legend(legendStr);
    grid on ;

    if(opts.saveResult)
      vl_xmkdir(opts.saveDir);
      figFile = fullfile(opts.saveDir,strcat(name,'.eps'));
      fprintf('\nSaving figure as eps graphics: %s\n',figFile);
      print('-depsc2',figFile);
      figFile = fullfile(opts.saveDir,strcat(name,'.fig'));
      fprintf('Saving figure as matlab figure to: %s\n',figFile);
      saveas(gca,figFile);
    end
    
end

function myprintf(fids,format,varargin)

  for i = 1:numel(fids)
    fprintf(fids(i),format,varargin{:});
  end
end

function plotDataset(images)

  numImages = numel(images);
  numCols = ceil(sqrt(numImages));
  numRows = ceil(numImages/numCols);

  for i = 1:numImages
    %colNo = 1+mod(i-1,numCols);
    %rowNo = 1+floor((i-1)/numCols);
    %subplot(numRows,numCols,(colNo-1)*numRows+rowNo);
    subplot(numRows,numCols,i);
    imshow(images{i}); title(sprintf('Image #%02d',i));
  end
  drawnow;
end

function plotFrames(framesA,framesB,framesA_,framesB_,iDetector,iImg,...
                    numDetectors,imageA,imageB,detectorName,matchIdxs)

    figure(iImg);
    subplot(numDetectors,2,2*(iDetector-1)+1) ; imshow(imageA);
    colormap gray ;
    hold on ; vl_plotframe(framesA);
    % Plot the transformed and matched frames from B on A in blue
    matchLogical = false(1,size(framesB_,2));
    matchLogical(matchIdxs) = true;
    vl_plotframe(framesB_(:,matchLogical),'b','linewidth',1);
    % Plot the remaining frames from B on A in red
    vl_plotframe(framesB_(:,~matchLogical),'r','linewidth',1);
    axis equal;
    set(gca,'xtick',[],'ytick',[]);
    ylabel(detectorName);
    title('Reference image detections');

    subplot(numDetectors,2,2*(iDetector-1)+2) ; imshow(imageB) ;
    hold on ; vl_plotframe(framesB) ;axis equal; axis off;
    %vl_plotframe(framesA_, 'b', 'linewidth', 1) ;
    title('Transformed image detections');

    drawnow;
end

function [bestMatches,matchIdxs] = findOneToOneMatches(ev,framesA,framesB, overlapError)
  matches = zeros(3,0);
  overlapThresh = 1 - overlapError;
  bestMatches = zeros(1, size(framesA, 2)) ;
  matchIdxs = [];

  for j=1:length(framesA)
    numNeighs = length(ev.scores{j}) ;
    if numNeighs > 0
      matches = [matches, ...
                 [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
    end
  end

  matches = matches(:,matches(3,:)>overlapThresh);

  % eliminate assigment by priority, i.e. sort the matches by the score
  [drop, perm] = sort(matches(3,:), 'descend');
  matches = matches(:, perm);
  % Create maps which frames has not been 'used' yet
  availA = true(1,size(framesA,2));
  availB = true(1,size(framesB,2));

  for idx = 1:size(matches,2)
    aIdx = matches(1,idx);
    bIdx = matches(2,idx);
    if(availA(aIdx) && availB(bIdx))
      bestMatches(aIdx) = 1;
      matchIdxs = [matchIdxs bIdx];
      availA(aIdx) = false;
      availB(bIdx) = false;
    end
  end
end
