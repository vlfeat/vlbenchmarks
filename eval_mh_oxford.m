function eval_kimharris(resultsPath)
if nargin < 1, resultsPath = ''; end;

import datasets.*;
import benchmarks.*;
import localFeatures.*;

set(0,'DefaultFigureVisible','off');


dataset_name = 'oxford';
for category_idx = 1:numel(datasets.VggAffineDataset.AllCategories)
    category_name = datasets.VggAffineDataset.AllCategories{category_idx};
    dataset = datasets.VggAffineDataset('Category', category_name);

    % --------------------------------------------------------------------
    % PART 1: Detector repeatability
    % --------------------------------------------------------------------

    siftDetector = VlFeatSift();
    mhDetector = MultiscaleHarris();
    mser = VlFeatMser();


    repBenchmark = RepeatabilityBenchmark('Mode','Repeatability');

    featExtractors = {siftDetector, mser, mhDetector};
    detectorNames = {'SIFT', 'MSER', 'MH'};

    repeatability = [];
    numCorresp = [];


        imageAPath = dataset.getImagePath(1);
        for d = 1:numel(featExtractors)
          for i = 2:dataset.NumImages
            [repeatability(d,i) numCorresp(d,i)] = ...
              repBenchmark.testFeatureExtractor(featExtractors{d}, ...
                                        dataset.getTransformation(i), ...
                                        dataset.getImagePath(1), ...
                                        dataset.getImagePath(i));
          end
        end

        printScores(detectorNames, 100 * repeatability, 'Repeatability');
        printScores(detectorNames, numCorresp, 'Number of correspondences');

        figure(2); clf; 
        plotScores(detectorNames, dataset, 100 * repeatability, 'Repeatability');
        printFigure(['results_' dataset_name], [category_name '_repeatability']);

        figure(3); clf; 
        plotScores(detectorNames, dataset, numCorresp, 'Number of correspondences');
        printFigure(['results_' dataset_name], [category_name '_num-correspondences']);


    % --------------------------------------------------------------------
    % PART 2: Detector matching score
    % --------------------------------------------------------------------

    mserWithSift = DescriptorAdapter(mser, siftDetector);
    mhWithSift = DescriptorAdapter(mhDetector, siftDetector);
    featExtractors = {siftDetector, mserWithSift, mhWithSift};
    detectorNames = {'SIFT', 'MSER with SIFT', 'MH with SIFT'};

    matchingBenchmark = RepeatabilityBenchmark('Mode','MatchingScore');

    matchScore = [];
    numMatches = [];

    for d = 1:numel(featExtractors)
      for i = 2:dataset.NumImages
        [matchScore(d,i) numMatches(d,i)] = ...
          matchingBenchmark.testFeatureExtractor(featExtractors{d}, ...
                                    dataset.getTransformation(i), ...
                                    dataset.getImagePath(1), ...
                                    dataset.getImagePath(i));
      end
    end


    printScores(detectorNames, matchScore*100, 'Match Score');
    printScores(detectorNames, numMatches, 'Number of matches') ;

    figure(5); clf; 
    plotScores(detectorNames, dataset, matchScore*100,'Matching Score');
    printFigure(['results_' dataset_name], [category_name '_matching_score']);

    figure(6); clf; 
    plotScores(detectorNames, dataset, numMatches,'Number of matches');
    printFigure(['results_' dataset_name], [category_name '_num-matches']);

end % datset category



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
  for k = 2:size(scores,2)
    fprintf('\tImg#%02d',k);
  end
  fprintf('\n');
  for k = 1:numDetectors
    fprintf(formatString,detectorNames{k});
    for l = 2:size(scores,2)
      fprintf('\t%6s',sprintf('%.2f',scores(k,l)));
    end
    fprintf('\n');
  end
end

function plotScores(detectorNames, dataset, score, titleText)
  xstart = max([find(sum(score,1) == 0, 1) + 1 1]);
  xend = size(score,2);
  xLabel = dataset.ImageNamesLabel;
  xTicks = dataset.ImageNames;
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
end


function printFigure(path, fileName, R, ext)
if isempty(path), return; end;
if ~exist(path, 'dir')
  mkdir(path) ;
end
if ~exist('R','var')
  R = 0.75;
end
vl_printsize(gcf, R) ;

if ~exist('ext','var')
  ext = 'pdf';
end
filePath = fullfile(path, [fileName '.' ext]) ;
saveas(gcf, filePath, ext)
end
