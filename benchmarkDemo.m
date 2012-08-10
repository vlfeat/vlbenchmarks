function benchmarkDemo()
% BENCHMARKDEMO Script demonstrating how to run the benchmarks for
%   different algorithms.
%
%   The following datasets are supported right now:
%     <a href="matlab: help affineDetectors.vggDataset">affineDetectors.vggDataset</a>
%
%   The following detectors are supported right now:
%     <a href="matlab: help affineDetectors.vlFeatDOG">affineDetectors.vlFeatDOG</a>
%     <a href="matlab: help affineDetectors.vlFeatMser">affineDetectors.vlFeatMser</a>
%     <a href="matlab: help affineDetectors.vggAffine">affineDetectors.vggAffine</a>
%     <a href="matlab: help affineDetectors.vggMser">affineDetectors.vggMser</a>
%     <a href="matlab: help affineDetectors.sfop">affineDetectors.sfop</a>
%
%   See <a href="matlab: help affineDetectors.exampleDetector">affineDetectors.exampleDetector</a> on how to add your own detector

import affineDetectors.*;

detectors{1} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5);
detectors{1}.detectorName = 'Censure initRad= 2.5';
detectors{2} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',3.5);
detectors{2}.detectorName = 'Censure initRad= 3.5';
detectors{3} = starDetector('response_threshold',30);
%detectors{4} = vlFeatDOG('PeakThresh',3/255);
%detectors{2} = affineDetectors.vggMser('ms',30); % Custom options
%detectors{3} = affineDetectors.vlFeatMser(); % Default options
%detectors{3}.detectorName = 'MSER(VLfeat)'; % You can change the default name that is
% used in the plot legend by modifying the above field
%detectors{1} = cmpHessian();
%detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',true,'Method','hessian');
%detectors{3} = vggAffine('Detector', 'hessian');
%detectors{3} = affineDetectors.vggAffine('Detector', 'harris');

%%% Orientation test
%detectors{1} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5,'KPdef',1);
%detectors{1}.detectorName = 'Censure with orient.';
%detectors{2} = cmpCensure('detectorType',1,'octRatio',2.5,'respThr',40,'initRadius',2.5);
%detectors{2}.detectorName = 'Censure';


datasets{1} = vggDataset('category','graf');
datasets{2} = vggDataset('category','bark');
datasets{3} = vggDataset('category','bikes');
datasets{4} = vggDataset('category','boat');
datasets{5} = vggDataset('category','leuven');
datasets{6} = vggDataset('category','trees');
datasets{7} = vggDataset('category','ubc');
datasets{8} = vggDataset('category','wall');

datasets{9} = transfDataset('image','boat.pgm','numImages',11,'category',{'zoom'},'startZoom',1,'endZoom',0.25);

for i=4
  % Initialise storage if it does not exist.
  storage = framesStorage(datasets{i}, 'calcDescriptors', true);
  storage.addDetectors(detectors);

  % TODO solve where to store tests - cell is not ideal storage because it
  % does not support adding new tests on demand...
  %tests = {repeatabilityTest(storage,'showQualitative',[])};
  %tests = {repeatabilityTest(storage), kristianEvalTest(storage)};
  %tests = {repeatabilityTest(storage),kristianEvalTest(storage,'CalcMatches',false)};
  tests = {kristianEvalTest(storage,'CalcMatches',true)};
  % Run tests.
  for j=1:numel(tests)
    tests{j}.runTest();
  end
end

function printScores(detectors, scores, name, outFile)
  % PRINTSCORES
  % Print the scores measured in the unified format to the standard 
  % output. If outFile defined, save the results to a file as well.
  numDetectors = numel(detectors);
  saveResults = nargin > 3 && ~isempty(outFile);

  if saveResults
    helpers.vl_xmkdir(fileparts(outFile));
    fH = fopen(outFile,'w');
    fidOut = [1 fH];
  else
    fidOut = 1;
  end

  maxNameLen = 0;
  detNames = cell(numDetectors,1);
  for k = 1:numDetectors
    detNames{k} = detectors{k}.getName();
    maxNameLen = max(maxNameLen,length(detNames{k}));
  end

  maxNameLen = max(length('Method name'),maxNameLen);
  obj.myprintf(fidOut,strcat('\nPriting ', name,':\n'));
  formatString = ['%' sprintf('%d',maxNameLen) 's:'];

  obj.myprintf(fidOut,formatString,'Method name');
  for k = 1:size(scores,2)
    obj.myprintf(fidOut,'\tImg#%02d',k);
  end
  obj.myprintf(fidOut,'\n');

  for k = 1:numDetectors
    myprintf(fidOut,formatString,detNames{k});
    for l = 1:size(scores,2)
      myprintf(fidOut,'\t%6s',sprintf('%.2f',scores(k,l)));
    end
    myprintf(fidOut,'\n');
  end

  if saveResults
    fclose(fH);
  end
  
  function myprintf(fids,format,varargin)
  % MYPRINTF
  % Helper extending printf to more outputs.
  % Parameters:
  %   fids    Array of output file idxs
  %   format, varargin See fprintf.
  for m = 1:numel(fids)
    fprintf(fids(m),format,varargin{:});
  end
  end
  
end

function plotScores(detectors, dataset, score, titleText, yLabel, outFile)
  % PLOTSCORES
  % Plot the scores into unified figure number figureNum. If 
  % opts.SaveResults is true, save the figure to opts.SaveDir/outFile
  %
  % Parameters:
  if isempty(score)
    warning('No scores to plot.');
    return
  end
  saveResults = nargin > 3 && ~isempty(outFile);

  xstart = max([find(sum(scores) == 0, 1) + 1 1]);

  figure(figureNum) ; clf ;
  xend = size(score,2);
  x_label = dataset.imageLabelsTitle;
  x_ticks = dataset.transformationName;
  plot(xstart:xend,score(:,xstart:xend)','linewidth', 3) ; hold on ;
  ylabel(yLabel) ;
  xlabel(x_label);
  set(gca,'XTick',xstart:1:xend);
  set(gca,'XTickLabel',x_ticks);
  title(titleText);
  set(gca,'xtick',1:size(score,2));

  maxScore = max([max(max(score)) 1]);
  meanEndValue = mean(score(:,xend));
  legendLocation = 'SouthEast';
  if meanEndValue < maxScore/2
    legendLocation = 'NorthEast';
  end

  legendStr = cell(1,numel(detectors));
  for m = 1:numel(detectors) 
    legendStr{m} = detectors{m}.getName(); 
  end
  legend(legendStr,'Location',legendLocation);
  grid on ;
  axis([xstart xend 0 maxScore]);

  if saveResults
    helpers.vl_xmkdir(fileparts(outFile));
    fprintf('\nSaving figure as eps graphics: %s\n',outFile);
    print('-depsc2', [outFile '.eps']);
    fprintf('Saving figure as matlab figure to: %s\n',figFile);
    saveas(gca,outFile,'fig');
  end
end

end
