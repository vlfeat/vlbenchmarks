function [mAP queriesAp] = retrievalDemo(resultsPath)
% RETRIEVALDEMO Demonstrates how to run the retrieval benchmark
%   RETRIEVALDEMO() Runs the repeatability demo.
%
%   RETRIEVALDEMO(RESULTS_PATH) Run the demo and save the results to
%   path RESULTS_PATH.

% Authors: Karel Lenc and Andrea Vedaldi

% AUTORIGHTS

if nargin < 1, resultsPath = ''; end;

% --------------------------------------------------------------------
% PART 1: Run the retrieval test
% --------------------------------------------------------------------

import localFeatures.*;
import datasets.*;
import benchmarks.*;

% Define the features extractors which will be tested with the retrieval
% benchmark.

featExtractors{1} = VlFeatCovdet('method', 'hessianlaplace', ...
                                 'estimateaffineshape', true, ...
                                 'estimateorientation', true, ...
                                 'peakthreshold',0.0035,...
                                 'doubleImage', false);
featExtractors{2} = VlFeatCovdet('method', 'harrislaplace', ...
                                 'estimateaffineshape', true, ...
                                 'estimateorientation', true, ...
                                 'peakthreshold',0.0000004,...
                                 'doubleImage', false);
featExtractors{3} = VlFeatSift('PeakThresh',2);

% Define the dataset which will be used for the benchmark. In this case we
% will use 'oxbuild' dataset (Philbin, CVPR07) which originally consists
% from 5k images. In order to compute the results in a reasonable time, we
% will select only subset of the images. Wrapper of this dataset uniformly
% samples the subsets.

dataset = VggRetrievalDataset('Category','oxbuild',...
                              'OkImagesNum',inf,...
                              'JunkImagesNum',100,...
                              'BadImagesNum',100);

% Define the benchmark class. This implements simple retrieval system which
% uses extracted features in a K-Nearest Neighbour search in order to
% retrieve queried images. Ranked set of retrieved images is then evaluated
% measuring the mean average precision of all queries.
% Parameter 'MaxNumImagesPerSearch' sets in how big chunks the dataset
% should be divided for the KNN search.
retBenchmark = RetrievalBenchmark('MaxNumImagesPerSearch',100);

% Run the test for all defined feature extractors
for d=1:numel(featExtractors)
  [mAP(d) info(d)] =...
    retBenchmark.testFeatureExtractor(featExtractors{d}, dataset);
end

% --------------------------------------------------------------------
% PART 2: Average precisions
% --------------------------------------------------------------------

detNames = {'VLF-heslap', 'VLF-harlap', 'VLF-SIFT'};

% For all the tested feature extractors we get single value which asses
% detector performance on the dataset.
figure(1); clf;
bar(mAP); grid on;
set(gca,'XTickLabel',detNames); 
ylabel('Mean average precision');
helpers.printFigure(resultsPath,'map',0.5);
printScores(detNames, mAP, {'mAP'});

% Calc average number of descriptors per dataset image
numDescriptors = cat(1,info(:).numDescriptors);
numQueryDescriptors = cat(1,info(:).numQueryDescriptors);
avgDescsNum(1,:) = mean(numDescriptors,2);
avgDescsNum(2,:) = mean(numQueryDescriptors,2);
printScores(detNames, avgDescsNum,{'Avg. #Descs.','Avg. #Query Descs.'});


% We can also plot the average precisions per each query as some detectors
% can be more useful 
figure(2); clf;
queriesAp = cat(1,info(:).queriesAp); % Values from struct to single array
selectedQAps = queriesAp(:,1:15); % Pick only first 15 queries
bar(selectedQAps');
grid on;
set(gca,'XTick',1:size(selectedQAps,2)); 
set(gca,'XLim',[0,size(selectedQAps,2)+1]);
legend(detNames,'Location','SE'); 
xlabel('Query #'); ylabel('Average precision');
helpers.printFigure(resultsPath,'queriesAp',0.6);

% --------------------------------------------------------------------
% PART 3: Precision recall curves
% --------------------------------------------------------------------

% More detailed results can be seen from the precision/recall curves which
% retain the retrieval system performance.

queryNum = 8;
query = dataset.getQuery(queryNum);

for d=1:numel(featExtractors)
  rankedList = info(d).rankedList(:,queryNum);
  [ap recall(:,d) precision(:,d)] = ...
    retBenchmark.rankedListAp(query, rankedList);
end
figure(7); clf;
plot(recall, precision,'LineWidth',2); 
xlabel('recall'); ylabel('Precision');
grid on; legend(detNames,'Location','SW');
helpers.printFigure(resultsPath,'prc',0.5);

% --------------------------------------------------------------------
% PART 4: Plot a query results
% --------------------------------------------------------------------

% Plot the query image with the query bbox
figure(5); clf;
image(imread(dataset.getImagePath(query.imageId)));
box = [query.box(1:2);query.box(3:4) - query.box(1:2)];
rectangle('Position',box,'LineWidth',2,'EdgeColor','y'); 
axis off;
helpers.printFigure(resultsPath,'query',0.6);

% Plot the retrieved images
rankedLists = {info(:).rankedList}; % Ranked list of the retrieved images
numViewedImages = 20;
figure(6); clf;
for d=1:numel(featExtractors)
  rankedList = rankedLists{d}(:,queryNum);
  for ri = 1:numViewedImages
    % We suppose that the first image is the query image itself
    imgId = rankedList(ri+1);
    imgPath = dataset.getImagePath(imgId);
    img = imread(imgPath);
    subplot(5,numViewedImages/5,ri); subimage(img); axis off;
    title(sprintf('Img %d (%s)',ri,getImageCategory(query,imgId)));
  end
  helpers.printFigure(resultsPath,['retrieved-',detNames{d}],0.8);
end


% --------------------------------------------------------------------
% Helper functions
% --------------------------------------------------------------------


function printScores(detectorNames, scores, names)
  maxDetNameLen = 0;
  for k = 1:numel(detectorNames)
    maxDetNameLen = max(maxDetNameLen,length(detectorNames{k}));
  end
  maxNameLen = 0;
  for k = 1:numel(names)
    maxNameLen = max(maxNameLen,length(names{k}));
  end
  fprintf('\n');
  detNameFormat = ['\t%' sprintf('%d',maxDetNameLen) 's'];
  nameFormat = ['%' sprintf('%d',maxNameLen) 's'];
  fprintf(nameFormat,'');
  cellfun(@(a) fprintf(detNameFormat,a),detectorNames);
  fprintf('\n');
  for k=1:numel(names)
    fprintf(nameFormat,names{k});
    arrayfun(@(a) fprintf(detNameFormat,sprintf('%.3f',a)),scores(k,:));
    fprintf('\n');
  end
end

function category = getImageCategory(query, imgId)
  if ismember(imgId,query.good)
    category = 'good';
  elseif ismember(imgId,query.ok)
    category = 'ok';
  elseif ismember(imgId,query.junk)
    category = 'junk';
  else
    category = 'bad';
  end
end

end
