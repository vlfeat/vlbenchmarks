classdef repeatabilityBenchmark < benchmarks.genericBenchmark
  %REPEATABILITYTEST Calc repeatability score of aff. cov. detectors test.
  %   repeatabilityTest(resultsStorage,'OptionName',optionValue,...)
  %   constructs an object for calculating repeatability score. 
  %
  %   Score is calculated when method runTest is invoked.
  %
  %   Options:
  %
  %   OverlapError :: [0.4]
  %   Maximal overlap error of ellipses to be considered as
  %   correspondences.
  %
  %   NormaliseFrames :: [true]
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
    defOverlapError = 0.4;
    defNormaliseFrames = true;
    defCacheMatches = false;
    keyPrefix = 'repeatability_';
    repFramesKeyPrefix = 'repFrames_';
  end
  
  methods
    function obj = repeatabilityBenchmark(varargin)
      name = 'repeatability';
      obj = benchmarks.genericBenchmark(name);
      
      obj.opts.overlapError = repeatabilityBenchmark.defOverlapError;
      obj.opts.normaliseFrames = repeatabilityBenchmark.defNormaliseFrames;
      obj.opts.cacheReprojectedFrames = repeatabilityBenchmark.defCacheReprojectedFrames;
      if numel(varargin) > 0
        obj.opts = commonFns.vl_argparse(obj.opts,varargin{:});
      end
      
    end
    
    function [repeatability numCorresp reprojFrames bestMatches] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)

      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageAPath);
      detSign = detector.getSignature();
      keyPrefix = repeatabilityBenchmark.keyPrefix;
      resultsKey = strcat(keyPrefix,detSign,imageASign,imageBSign);
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        [framesA] = detector.extractFeatures(imageAPath);
        [framesB] = detector.extractFeatures(imageBPath);
      
        [repeatability numCorresp reprojFrames bestMatches] = ... 
          testFeatures(obj,tf,framesA, framesB);
        
        if obj.opts.cacheReprojectedFrames
          results = {repeatability numCorresp reprojFrames bestMatches};
        else
          results = {repeatability numCorresp [] []};
        end
        
        DataCache.storeData(results, resultsKey);
      else
        [repeatability numCorresp reprojFrames bestMatches] = cachedResults{:};
      end
      
    end
   
    function [repeatability numCorresp reprojFrames bestMatches] = ... 
                testFeatures(obj, tf, imageAPath, imageBPath, framesA, framesB)
      import benchmarks.helpers.*;
      
      normFrames = obj.opts.normaliseFrames;
      overlErr = obj.opts.overlapError;
      
      imageA = imread(imageAPath);
      imageB = imread(imageBPath);
      [cropFramesA,cropFramesB,repFramesA,repFramesB] = ...
        cropFramesToOverlapRegion(framesA,framesB,tf,imageA,imageB);

      frameMatches = matchEllipses(repFramesB, cropFramesA,'NormaliseFrames',normFrames);
      bestMatches = findOneToOneMatches(frameMatches,cropFramesA,repFramesB,overlErr);
      numBestMatches = sum(bestMatches ~= 0);
      repeatability = numBestMatches / min(size(framesA,2), size(framesB,2));
      numCorresp = numBestMatches;
      
      reprojFrames = {cropFramesA,cropFramesB,repFramesA,repFramesB};
    end
  end 
    
  methods (Static)
      
    function plotFrameMatches(reprojectedFrames, bestMatches,...
                              imageAPath, imageBPath, figA, figB)
      
      imageA = imread(imageAPath);
      imageB = imread(imageBPath);
      
      [cropFramesA,cropFramesB,repFramesA,repFramesB] = reprojectedFrames;
      
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

