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
opts.calcMatches = false;
opts.overlapError = 0.4;
opts = commonFns.vl_argparse(opts,varargin);


% -------- Compute each detectors output and store the evaluation --------------


if(opts.verifyKristian)
  repScoreKristian  = zeros(numDetectors,numImages);
  matchScoreKristian  = zeros(numDetectors,numImages);
  numOfCorrespKristian  = zeros(numDetectors,numImages);
  numOfMatchesKristian  = zeros(numDetectors,numImages);
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

for iDetector = 1:numel(detectors)
  

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
    if opts.calcMatches && ~isempty(descriptors)
        [repScoreKristian(iDetector,:), numOfCorrespKristian(iDetector,:),...
        matchScoreKristian(iDetector,:), numOfMatchesKristian(iDetector,:)] ...
                = runKristianEval(frames,imagePaths,images,tfs, ...
                                  opts.overlapError, descriptors);
    else
        [repScoreKristian(iDetector,:), ...
        numOfCorrespKristian(iDetector,:)] = runKristianEval(frames,imagePaths,...
                                                            images,tfs, opts.overlapError);
    end
        
  end

end

repeatibilityScore = repeatibilityScore * 100;
fprintf('\n------ Evaluation completed ---------\n');

% ----------------- Plot the evaluation scores ---------------------------------
fn = numImages; % Number of figure
plotScores(fn,'detectorEval', repeatibilityScore, ...
           'Detector repeatibility vs. image index', ...
           'Image #','Repeatibility. %',detectors, opts, 1); fn = fn + 1;
plotScores(fn, 'numCorrespond', numOfCorresp, ...
           'Detector num. of correspondences vs. image index', ...
           'Image #','#correspondences',detectors, opts, 2); fn = fn + 1;
if(opts.verifyKristian)
  plotScores(fn, 'KM_repeatability', repScoreKristian, ...
             'KM Detector repeatibility vs. image index', ...
             'Image #','Repeatibility. %',detectors, opts, 1); fn = fn + 1;
  plotScores(fn, 'KM_numCorrespond', numOfCorrespKristian, ...
             'KM Detector num. of correspondences vs. image index', ...
             'Image #','#correspondences',detectors, opts, 2); fn = fn + 1;
  if opts.calcMatches
    plotScores(fn, 'KM_matchScore', matchScoreKristian, ...
               'KM Detector matching score vs. image index', ...
               'Image #','Matching score %',detectors, opts, 1); fn = fn + 1;
    plotScores(fn, 'KM_numMatches', numOfMatchesKristian, ...
               'KM Detector num of matches vs. image index', ...
               'Image #','#correct matches',detectors, opts, 2);
  end
end
       
% -------- Print out and save the scores --------------------
detNames = printScores(opts,detectors,repeatibilityScore,'detectorEval.txt', 'repeatability scores');
printScores(opts,detectors,numOfCorresp,'numCorresp.txt', 'num. of correspondences');
if(opts.verifyKristian)
  fprintf('\nOutput of Kristians benchmark:\n');
  printScores(opts,detectors,repScoreKristian,'detectorEvalKristianRepScore.txt', 'KM repeatability scores');
  printScores(opts,detectors,numOfCorrespKristian,'detectorEvalKristianCorrNum.txt', 'KM num. of correspondences');
  if opts.calcMatches
    printScores(opts,detectors,matchScoreKristian,'detectorEvalKristianMatchScore.txt', 'KM match scores');
    printScores(opts,detectors,numOfMatchesKristian,'detectorEvalKristianMatchesNum.txt', 'KM num. of matches');
  end
end

if(opts.saveResult)
  matFile = fullfile(opts.saveDir,'detectorEval.mat');
  save(matFile,'detNames','repeatibilityScore');
  fprintf('\nScores saved to: %s\n',matFile);
end

end
