classdef matchingBenchmark < benchmarks.genericBenchmark & helpers.Logger
  %REPEATABILITYTEST Calc repeatability score of aff. cov. detectors test.
  %   repeatabilityTest(resultsStorage,'OptionName',optionValue,...)
  %   constructs an object for calculating repeatability score. 
  %
  %   Score is calculated when method runTest is invoked.
  %
  %   Options:
  %
  %   OverlapError :: [0.5]
  %   Maximal overlap error of ellipses to be considered as
  %   correspondences.
  %
  %   NormaliseFrames :: [false]
  %   Normalise the frames to constant scale (defaults is true for detector
  %   repeatability tests, see Mikolajczyk et. al 2005).
  %
  %   CacheReprojectedFrames :: [false]
  %   Store reprojected frames and best matches. When false saves amount of
  %   data stored in cache but does not allow to plot matches afterwards.
  %
  
  properties
    opts                % Local options of repeatabilityTest
  end
  
  properties(Constant)
    defOverlapError = 0.5;
    defNormaliseFrames = false;
    defCacheReprojectedFrames = false;
    defMagnification = 3;
    keyPrefix = 'matching';
    repFramesKeyPrefix = 'reprojectedFrames';
  end
  
  methods
    function obj = matchingBenchmark(varargin)
      import benchmarks.*;
      obj.benchmarkName = 'matching';
      
      obj.opts.overlapError = matchingBenchmark.defOverlapError;
      obj.opts.normaliseFrames = matchingBenchmark.defNormaliseFrames;
      obj.opts.cacheReprojectedFrames = matchingBenchmark.defCacheReprojectedFrames;
      obj.opts.magnification  = matchingBenchmark.defMagnification;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.benchmarkName,varargin);
    end
    
     function [matchingScore numMatches bestMatches reprojFrames] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)

      import benchmarks.*;
      import helpers.*;
      
      obj.info('Comparing frames from det. %s and images %s and %s.',...
          detector.detectorName,getFileName(imageAPath),getFileName(imageBPath));
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      detSign = detector.getSignature();
      resultsKey = cell2str({obj.keyPrefix,detSign,imageASign,imageBSign});
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        [framesA descriptorsA] = detector.extractFeatures(imageAPath);
        [framesB descriptorsB] = detector.extractFeatures(imageBPath);
      
        [matchingScore numMatches bestMatches reprojFrames] = ... 
          testFeatures(obj,tf,framesA,framesB,descriptorsA, descriptorsB);
        
        if obj.opts.cacheReprojectedFrames
          results = {matchingScore numMatches bestMatches reprojFrames };
        else
          results = {matchingScore numMatches [] []};
        end
        
        helpers.DataCache.storeData(results, resultsKey);
      else
        [matchingScore numMatches bestMatches reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end
      
    end
   
    function [matchingScore numMatches bestMatches reprojFrames] = ... 
                testFeatures(obj, tf, framesA, framesB, descriptorsA, descriptorsB)
      import benchmarks.helpers.*;
      import helpers.*;
      
      startTime = tic;
      normFrames = obj.opts.normaliseFrames;
      overlErr = obj.opts.overlapError;
      
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;
      
      [reprojFramesA,reprojFramesB] = reprojectFrames(framesA, framesB, tf);

      magFactor = obj.opts.magnification^2;
      framesA(3:5,:) = framesA(3:5,:).*magFactor;
      reprojFramesB(3:5,:) = reprojFramesB(3:5,:).*magFactor;
      
      % Find all ellipses with sufficient overlap
      obj.info('Computing overlaps between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      frameMatches = matchEllipses(reprojFramesB, framesA,'NormaliseFrames',normFrames);

      % Calculate the one-to-one matches based on distances in descriptor
      % domain
      numFramesA = size(framesA,2);
      numFramesB = size(reprojFramesB,2);
      bestMatches = zeros(2, numFramesA) ;
      
      obj.info('Computing cross distances between all descriptors');
      dists = vl_alldist2(single(descriptorsA),single(descriptorsB));
      obj.info('Sorting distances')
      [dists, perm] = sort(dists(:),'ascend');

      overlThresh = 1 - overlErr;

      [aIdx bIdx] = ind2sub([numFramesA, numFramesB],perm(1:numel(dists)));
      edges = [aIdx bIdx];
     
      obj.info('Computing matching');
      matches = benchmarks.helpers.greedyBipartiteMatching(numFramesA, numFramesB, edges);
      
      for aIdx=1:numFramesA
        bIdx = matches(aIdx);
        [hasCorresp bCorresp] = ismember(bIdx,frameMatches.neighs{aIdx});
        if hasCorresp && frameMatches.scores{aIdx}(bCorresp) > overlThresh
          bestMatches(1,aIdx) = bIdx;
          bestMatches(2,aIdx) = frameMatches.scores{aIdx}(bCorresp);
        end
      end
      
      numMatches = sum(bestMatches(1,:) ~= 0);
      matchingScore = numMatches / min(size(framesA,2), size(framesB,2));
      
      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
      
      obj.info('Matching score: %g \t Num. of matches: %g',matchingScore,numMatches);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),timeElapsed);
    end
  end 
    
  methods (Static)
      
    function plotFrameMatches(reprojectedFrames, bestMatches,...
                              imageAPath, imageBPath, figA, figB)
      
      imageA = imread(imageAPath);
      imageB = imread(imageBPath);
      
      [cropFramesA,cropFramesB,repFramesA,repFramesB] = reprojectedFrames{:};
      
      figure(figA); 
      imshow(imageA);
      colormap gray ;
      hold on ; vl_plotframe(cropFramesA,'linewidth', 1);
      % Plot the transformed and matched frames from B on A in blue
      vl_plotframe(repFramesB(:,bestMatches~=0),'b','linewidth',1);
      % Plot the remaining frames from B on A in red
      vl_plotframe(repFramesB(:,bestMatches==0),'r','linewidth',1);
      axis equal;
      set(gca,'xtick',[],'ytick',[]);
      title('Reference image detections');

      figure(figB); 
      imshow(imageB) ;
      hold on ; vl_plotframe(framesB,'linewidth', 1); axis equal; axis off;
      %vl_plotframe(framesA_, 'b', 'linewidth', 1) ;
      title('Transformed image detections');
    end
    
  end
  
end

