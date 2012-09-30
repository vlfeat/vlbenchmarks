function testVLFeatCovdet(testDescriptors)
% BENCHMARKDEMO Demonstrates how to run the feature repatability benchmark

% Author: Karel Lenc and Andrea Vedaldi

% AUTORIGHTS

  import localFeatures.*;
  import datasets.*;
  import benchmarks.*;

  helpers.DataCache.autoClear = false

  % good setting for repeatability
  detectors = {} ;
  detectorNames = {} ;
  if 0
    detectors{end+1} = VlFeatCovdet('method', 'hessianlaplace', ...
                                    'estimateaffineshape', true, ...
                                    'peakThreshold', 0.002, ...
                                    'edgeThreshold', 10, ...
                                    'estimateorientation', true, ...
                                    'doubleImage', false);
    detectorNames{end+1} = 'VLFeat Covdet ori' ;
  end

  for dbl = [false true]
    for det = {'DoG', 'Hessian', 'HessianLaplace', 'HarrisLaplace'}
      %for det = {'HessianLaplace'}
      detectors{end+1} = VlFeatCovdet('method', char(det), ...
                                      'estimateaffineshape', true, ...
                                      'estimateorientation', false, ...
                                      'doubleImage', dbl, ...
                                      'format', 'uint8');
      detectorNames{end+1} = sprintf('VL %s dbl:%d', char(det), dbl) ;
    end
  end

  if 1
    detectors{end+1} = VlFeatSift() ;
    detectorNames{end+1} = 'VLFeat SIFT' ;
  end

  % VGG + SIFT descriptor
  if 1
    descDet = VggDescriptor('CropFrames',true,'Magnification',3);

    detectors{end+1} = DescriptorAdapter(...
      VggAffine('Detector','hesaff','Threshold',500), descDet);
    detectorNames{end+1} = 'VGG hes' ;

    detectors{end+1} = DescriptorAdapter(...
      VggAffine('Detector','haraff','Threshold',1000), descDet);
    detectorNames{end+1} = 'VGG har' ;
  end

  %repeatability(detectors,detectorNames, false) ;
  retrieval(detectors,detectorNames, false) ;
end

% --------------------------------------------------------------------
function retrieval(detectors, detectorNames, testDescriptors)
% --------------------------------------------------------------------

  import localFeatures.*;
  import datasets.*;
  import benchmarks.*;

  dataset = VggRetrievalDataset('Category','oxbuild','Lite',false);

  retBenchmark = RetrievalBenchmark('maxNumImagesPerSearch',200);

  helpers.DataCache.autoClear = false

  mAP = zeros(numel(detectors),1);
  queryAPs = zeros(numel(detectors),dataset.NumQueries);

  for d=1:numel(detectors)
    [mAP(d) queryAPs(d,:)] = retBenchmark.evalDetector(detectors{d}, dataset);
  end

  printScores(detectorNames, 100 * mAP, 'mAP');
end

% --------------------------------------------------------------------
function repeatability(detectors, detectorNames, testDescriptors)
% --------------------------------------------------------------------

  import localFeatures.*;
  import datasets.*;
  import benchmarks.*;

  helpers.DataCache.autoClear = false

  if nargin < 3
    testDescriptors = false ;
  end

  dataset = VggAffineDataset('category','graf');

  repBenchmark = RepeatabilityBenchmark(...
    'MatchFramesGeometry',true,...
    'MatchFramesDescriptors',testDescriptors,...
    'CropFrames',true,...
    'NormaliseFrames',true,...
    'OverlapError',0.4);


  if 0
    switch 2
      case 1
        imagePath = dataset.getImagePath(1) ;
        im = imread(imagePath) ;
        im = im(end-150:end,1:150,:) ;
        imagePath = '/tmp/blobs1.png' ;
        imwrite(im, imagePath) ;
      case 2
        imagePath = '/tmp/blobs1.png' ;
        im = vl_impattern('threedotssquare') ;
        imwrite(im, imagePath) ;
    end
    fa = detectors{1}.extractFeatures(imagePath);
    fb = detectors{3}.extractFeatures(imagePath);

    figure(1) ;clf;
    imagesc(imread(imagePath)) ;hold on;
    vl_plotframe(fa,'b') ;
    vl_plotframe(fb,'c') ;
    vl_printsize(3) ;
    colormap gray ;
    axis image ;
    print('-dpdf', '~/a.pdf') ;
    return ;
  end


  % Print and plot the results
  repeatability = [] ;
  numCorresp = [] ;
  for d = 1:numel(detectors)
    for i = 2:dataset.NumImages
      [repeatability(d,i) numCorresp(d,i)] = ...
          repBenchmark.testDetector(detectors{d}, ...
                                    dataset.getTransformation(i), ...
                                    dataset.getImagePath(1), ...
                                    dataset.getImagePath(i)) ;
    end
  end

  % The scores can now be prented, as well as visualized in a
  % graph. This uses two simple functions defined below in this file.

  printScores(detectorNames, 100 * repeatability, 'Repeatability');
  printScores(detectorNames, numCorresp, 'Number of correspondences');

  figure(2); clf;
  subplot(1,2,1);
  plotScores(detectorNames, dataset, 100 * repeatability, 'Repeatability');
  subplot(1,2,2);
  plotScores(detectorNames, dataset, numCorresp, 'Number of correspondences');
end

% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------

function printScores(detectorNames, scores, name)
  numDetectors = numel(detectorNames);
  maxNameLen = length('Method name');
  for k = 1:numDetectors
    maxNameLen = max(maxNameLen,length(detectorNames{k}));
  end
  fprintf(['\n', name,':\n']);
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
