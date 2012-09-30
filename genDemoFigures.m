function genDemoFigures()
% GENDEMOFIGURES Generate documentation demo figures

figure(1); clf;
sift = localFeatures.VlFeatSift();
thrSift = localFeatures.VlFeatSift('PeakThresh',11);

ellBlobs = datasets.helpers.genEllipticBlobs('Width',500,'Height',500,...
  'NumDeformations',4);
ellBlobsPath = 'ellBlobs.png';
imwrite(ellBlobs,ellBlobsPath);

siftFrames = sift.extractFeatures(ellBlobsPath);
bigScaleSiftFrames = thrSift.extractFeatures(ellBlobsPath);

imshow(ellBlobs);
sfH = vl_plotframe(siftFrames,'g');
bssfH = vl_plotframe(bigScaleSiftFrames,'r','LineWidth',1);
legend([sfH bssfH],'SIFT','SIFT PT=10','Location','SE');
printFigure('siftFrames',0.9);

repBenchmark = benchmarks.RepeatabilityBenchmark('Mode','Repeatability');
dataset = datasets.VggAffineDataset('Category','graf');

mser = localFeatures.VlFeatMser();
detectors = {sift, thrSift, mser};

% Prealocate the results
rep = zeros(numel(detectors),dataset.NumImages);
numCorr = zeros(numel(detectors),dataset.NumImages);

imageAPath = dataset.getImagePath(1);
for detIdx = 1:numel(detectors)
  detector = detectors{detIdx};
  for imgIdx = 2:dataset.NumImages
    imageBPath = dataset.getImagePath(imgIdx);
    tf = dataset.getTransformation(imgIdx);
    [rep(detIdx,imgIdx) numCorr(detIdx,imgIdx)] = ...
      repBenchmark.testDetector(detector, tf, imageAPath,imageBPath);
  end
end

detNames = {'SIFT','SIFT PT=10','MSER'};
clf; plot(rep'.*100,'LineWidth',2); legend(detNames); 
xlabel('Image #'); ylabel('Repeatability [%]');
set(gca,'XTick',2:6); axis([2 6 0 100]); grid on;
printFigure('repeatability',0.6);
clf; plot(numCorr','LineWidth',2); legend(detNames);
xlabel('Image #'); ylabel('Number of Correspondences'); 
axis([2 6 0 max(numCorr(:))]); set(gca,'XTick',2:6); grid on;
printFigure('numCorresp',0.6);

imgBIdx = 3;
imageBPath = dataset.getImagePath(imgBIdx);
tf = dataset.getTransformation(imgBIdx);
[r nc siftCorresps siftReprojFrames] = ...
  repBenchmark.testDetector(sift, tf, imageAPath,imageBPath);

clf;
imshow(imread(imageBPath));
benchmarks.helpers.plotFrameMatches(siftCorresps,siftReprojFrames,...
  'IsReferenceImage',false,'PlotMatchLine',false,'PlotUnmatched',false);
printFigure('correspondences',0.75);

matchingBenchmark = benchmarks.RepeatabilityBenchmark('Mode','MatchingScore');

mserWithSift = localFeatures.DescriptorAdapter(mser, sift);
detectors = {sift, thrSift, mserWithSift};

matching = zeros(numel(detectors),dataset.NumImages);
numMatches = zeros(numel(detectors),dataset.NumImages);

for detIdx = 1:numel(detectors)
  detector = detectors{detIdx};
  for imgIdx = 2:dataset.NumImages
    imageBPath = dataset.getImagePath(imgIdx);
    tf = dataset.getTransformation(imgIdx);
    [matching(detIdx,imgIdx) numMatches(detIdx,imgIdx)] = ...
      matchingBenchmark.testDetector(detector, tf, imageAPath,imageBPath);
  end
end

detNames = {'SIFT','SIFT PT=10','MSER with SIFT'};
clf; plot(matching'.*100,'LineWidth',2); legend(detNames); 
xlabel('Image #'); ylabel('Matching Score [%]');
set(gca,'XTick',2:6); axis([2 6 0 100]); grid on; 
printFigure('matchingScore',0.6);
clf; plot(numMatches','LineWidth',2); legend(detNames);
xlabel('Image #'); ylabel('Number of Matches'); 
axis([2 6 0 max(numMatches(:))]); set(gca,'XTick',2:6); grid on;
printFigure('numMatches',0.6);

imgBIdx = 3;
imageBPath = dataset.getImagePath(imgBIdx);
tf = dataset.getTransformation(imgBIdx);
[r nc siftCorresps siftReprojFrames] = ...
  matchingBenchmark.testDetector(sift, tf, imageAPath,imageBPath);

clf;
imshow(imread(imageBPath));
benchmarks.helpers.plotFrameMatches(siftCorresps,siftReprojFrames,...
  'IsReferenceImage',false,'PlotMatchLine',false,'PlotUnmatched',false);
printFigure('matches',0.75);

function printFigure(fileName, R)
  figDir = fullfile(pwd,'doc','demo') ;
  if ~ exist(figDir, 'dir')
    mkdir(figDir) ;
  end
  if ~exist('R','var')
    R = 0.75;
  end
  vl_printsize(gcf, R) ;
  filePath = fullfile(figDir, [fileName '.eps']) ;
  print(gcf, '-depsc2',filePath) ;
  fprintf('%s: wrote file ''%s''\n', mfilename,  filePath) ;
end
end