function runBenchmark(detectors)
% Function to run a affine co-variant feature detector on
% dataset of images, and measure repeatibility

import affineDetectors.*;

conf.dataDir  = 'data' ; % TODO: make this relative to the current m file, ask Andrea if vlfeat has a fn
conf.imageSel = [1 2] ;


% -------- Load the dataset ----------------------------------------------------
images = cell(1,6);
for i=1:6
  imagePath = fullfile(conf.dataDir, 'graf', sprintf('img%d.ppm',i)) ;
  images{i} = imread(imagePath) ;
  tfs{i} = textread(fullfile(conf.dataDir, 'graf', sprintf('H1to%dp', i))) ;
end

% -------- Evaluate each detector output and plot it ---------------------------
numDetectors = numel(detectors);
repeatibilityScore = zeros(numDetectors,6); repeatibilityScore(:,1)=1;

% Clear all the figures
for i = 2:6, figure(i); clf; end

for iDetector = 1:numel(detectors)
  curDetector = detectors(iDetector);
  assert(isa(curDetector,'affineDetectors.genericDetector'),...
         'Detector not an instance of genericDetector\n');
  frames = cell(1,6);

  fprintf('\nComputing affine covariant regions for method #%02d: %s\n\n', ...
          iDetector, curDetector.getName());

  for i = 1:6
    fprintf('Computing regions for image: %02d/%02d ...\r',i,6);
    frames{i} = curDetector.detectPoints(images{i});
  end

  fprintf('\n');

  for i=2:6
  fprintf('Evaluating regions for image: %02d/%02d ...\n',i,6);
    [framesA,framesB,framesA_,framesB_] = ...
        cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i});

    plotFrames(framesA,framesB,framesA_,framesB_,iDetector,i,numDetectors,...
               images{1},images{i},curDetector.getName());

    frameMatches = matchEllipses(framesB_, framesA) ;
    bestMatches = findOneToOneMatches(frameMatches,framesA,framesB_);
    repeatibilityScore(iDetector,i) = ...
        sum(bestMatches) / min(size(framesA,2), size(framesB,2));
  end

end

figure(100) ; clf ;
plot(repeatibilityScore' * 100,'linewidth', 3) ; hold on ;
ylabel('repeatab. %') ;
xlabel('image') ;
ylim([0 100]) ;

legendStr = cell(1,numel(detectors));
for i = 1:numel(detectors), legendStr{i} = detectors(i).getName(); end
legend(legendStr);
grid on ;

function plotFrames(framesA,framesB,framesA_,framesB_,iDetector,iImg,...
                    numDetectors,imageA,imageB,detectorName)

    figure(iImg);
    subplot(numDetectors,2,2*(iDetector-1)+1) ; imagesc(imageA);
    colormap gray ;
    hold on ; vl_plotframe(framesA) ; axis off;
    title(detectorName);

    subplot(numDetectors,2,2*(iDetector-1)+2) ; imagesc(imageB) ;
    hold on ; vl_plotframe(framesA_) ; axis off;
    vl_plotframe(framesB, 'b', 'linewidth', 1) ;
    title(detectorName);

function [framesA,framesB,framesA_,framesB_] = ...
    cropFramesToOverlapRegion(framesA,framesB,tfs,imageA,imageB)
% This function transforms ellipses in A to B (and vice versa), and crops
% them according to their visibility in the transformed frame

  import affineDetectors.*;

  framesA = helpers.frameToEllipse(framesA) ;
  framesB = helpers.frameToEllipse(framesB) ;

  framesA_ = helpers.warpEllipse(tfs,framesA) ;
  framesB_ = helpers.warpEllipse(inv(tfs),framesB) ;

  % find frames fully visible in both images
  bboxA = [1 1 size(imageA, 2) size(imageA, 1)] ;
  bboxB = [1 1 size(imageB, 2) size(imageB, 1)] ;

  selA = helpers.isEllipseInBBox(bboxA, framesA ) & ...
         helpers.isEllipseInBBox(bboxB, framesA_);

  selB = helpers.isEllipseInBBox(bboxA, framesB_) & ...
         helpers.isEllipseInBBox(bboxB, framesB );

  framesA  = framesA(:, selA);
  framesA_ = framesA_(:, selA);
  framesB  = framesB(:, selB);
  framesB_ = framesB_(:, selB);

function bestMatches = findOneToOneMatches(ev,framesA,framesB)
  matches = [] ;
  bestMatches = zeros(1, size(framesA, 2)) ;

  for j=1:length(framesA)
    numNeighs = length(ev.scores{j}) ;
    if numNeighs > 0
      matches = [matches, ...
                 [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
    end
  end

  % eliminate assigment by priority
  [drop, perm] = sort(matches(3,:), 'descend') ;
  matches = matches(:, perm) ;

  idx = 1 ;
  while idx < size(matches,2)
    isDup = (matches(1, idx+1:end) == matches(1, idx)) | ...
            (matches(2, idx+1:end) == matches(2, idx)) ;
    matches(:, find(isDup) + idx) = [] ;
    idx = idx + 1 ;
  end

  bestMatches(matches(1, matches(3, :) > .6)) = 1 ;
  % 0.6 is the overlap threshold, TODO: make this a parameter
