function [mAP queryAPs] = retrievalBenchmarkDemo()
% RETRIEVALBENCHMARKDEMO Demo of retrieval benchmark usage
import localFeatures.*;
import datasets.*;
import benchmarks.*;

%% Define Local features detectors
detectors{1} = DescriptorAdapter(VggAffine('Detector','haraff'),VggDescriptor());
detectors{2} = DescriptorAdapter(VggMser(),VggDescriptor());
%detectors{3} = CmpBinHessian();
% For MSERs use VGG SIFT as descriptors
%detectors{4} = DescriptorAdapter(VggMser(),VggDescriptor());

%% Define dataset
dataset = VggRetrievalDataset('Category','oxbuild','BadImagesNum',0,'JunkImagesNum',0,'OkImagesNum',0);

%% Run the benchmark
retBenchmark = RetrievalBenchmark('k',50);

mAP = zeros(numel(detectors),1);
queryAPs = zeros(numel(detectors),dataset.NumQueries);
rankedLists = cell(1,numel(detectors));
votes = cell(1,numel(detectors));
numDescriptors = cell(1,numel(detectors));

for d=1:numel(detectors)
  [mAP(d) queryAPs(d,:) rankedLists{d} votes{d} numDescriptors{d}] =...
    retBenchmark.evalDetector(detectors{d}, dataset);
end

%% Plot the results
detNames = cellfun(@(a) a.Name,detectors,'UniformOutput',false);

figure(1); clf;
bar(mAP); set(gca,'XTickLabel',detNames); ylabel('Mean average precision');


figure(2); clf;
bar(queryAPs'); set(gca,'XTick',1:size(queryAPs,2)); 
set(gca,'XLim',[0,size(queryAPs,2)+1]);
legend(detNames,'Location','NW'); xlabel('Query #');ylabel('Average precision');

allDescriptorsNum = cellfun(@mean,numDescriptors);
figure(3); clf;
bar(allDescriptorsNum); set(gca,'XTickLabel',detNames); 
ylabel('Number of descriptors in the database');

%% Draw the query and its results

queryNum = 40;
detNum = 1;
query = dataset.getQuery(queryNum);
queryVotes = votes{detNum}(:,queryNum);
% Plot the voting score of the retrieved images
numImages = 20;
figure(4); clf;
bar(queryVotes(2:numImages+1)./queryVotes(1));
xlabel('Image #'); ylabel('Normalised voting score');
% Plot the query image with the query bbox
figure(5); clf;
image(imread(dataset.getImagePath(query.imageId))); 
title('Query image'); axis off;
rectangle('Position',query.box,'LineWidth',2,'EdgeColor','y');
title('Query Image with query bbox.');

% Plot the retrieved images
figure(6); clf;
rankedList = rankedLists{detNum}(:,queryNum);

for ri = 1:numImages
  % We suppose that the first image is the query image itself
  imgId = rankedList(ri+1);
  imgPath = dataset.getImagePath(imgId);
  img = imread(imgPath);
  subplot(4,numImages/4,ri); subimage(img); axis off;
  title(sprintf('Image %d (%s)',ri,getImageCategory(query,imgId)));
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
