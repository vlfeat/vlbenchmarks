classdef repeatabilityBenchmark < benchmarks.genericBenchmark & helpers.Logger
  %REPEATABILITYBENCHMARK Calc repeatability score of im. features detector
  %   repeatabilityTest(resultsStorage,'OptionName',optionValue,...)
  %   constructs an object for calculating repeatability score. 
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
  
  properties
    opts                % Local options of repeatabilityTest
  end
  
  properties(Constant)
    defOverlapError = 0.4;
    defNormaliseFrames = true;
    keyPrefix = 'repeatability';
    reprojFramesKeyPrefix = 'reprojectedFrames';
  end
  
  methods
    function obj = repeatabilityBenchmark(varargin)
      import benchmarks.*;
      obj.benchmarkName = 'repeatability';
      
      obj.opts.overlapError = repeatabilityBenchmark.defOverlapError;
      obj.opts.normaliseFrames = repeatabilityBenchmark.defNormaliseFrames;
      if numel(varargin) > 0
        [obj.opts varargin] = vl_argparse(obj.opts,obj.remArgs);
      end
      obj.configureLogger(obj.benchmarkName,varargin);
    end
    
    function [repeatability numCorresp bestMatches reprojFrames] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)

      import benchmarks.*;
      import helpers.*;
      
      obj.info('Comparing frames from det. %s and images %s and %s.',...
          detector.detectorName,getFileName(imageAPath),getFileName(imageBPath));
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      resultsKey = cell2str({obj.keyPrefix, obj.getSignature(), ...
        detector.getSignature(), imageASign, imageBSign});
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        [framesA] = detector.extractFeatures(imageAPath);
        [framesB] = detector.extractFeatures(imageBPath);
      
        [repeatability numCorresp bestMatches reprojFrames] = ... 
          testFeatures(obj,tf,imageAPath, imageBPath,framesA, framesB);
        
        results = {repeatability numCorresp bestMatches reprojFrames };
        
        helpers.DataCache.storeData(results, resultsKey);
      else
        [repeatability numCorresp bestMatches reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end
      
    end
   
    function [repeatability numCorresp bestMatches reprojFrames] = ... 
                testFeatures(obj, tf, imageAPath, imageBPath, framesA, framesB)
      import benchmarks.helpers.*;
      import helpers.*;
      
      obj.info('Computing repeatability between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      
      startTime = tic;
      normFrames = obj.opts.normaliseFrames;
      overlErr = obj.opts.overlapError;
      
      imageA = imread(imageAPath);
      imageB = imread(imageBPath);
      imageASize = size(imageA);
      imageBSize = size(imageB);
      clear imageA;
      clear imageB;
      
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;
      
      [reprojFramesA,reprojFramesB] = reprojectFrames(framesA, framesB, tf);
      [visibleFramesA visibleFramesB] = framesInOverlapRegions(framesA, ...
        reprojFramesA, framesB, reprojFramesB, imageASize, imageBSize);
      
      framesA = framesA(:,visibleFramesA);
      reprojFramesA = reprojFramesA(:,visibleFramesA);
      framesB = framesB(:,visibleFramesB);
      reprojFramesB = reprojFramesB(:,visibleFramesB);

      % Find all ellipse matches
      frameMatches = matchEllipses(reprojFramesB, framesA,'NormaliseFrames',normFrames);
      
      % Find the best one-to-one matches
      nA = size(framesA,2);
      nB = size(reprojFramesB,2);
      bestMatches = findOneToOneMatches(frameMatches,nA,nB,overlErr);
      
      numBestMatches = sum(bestMatches(1,:) ~= 0);
      repeatability = numBestMatches / min(size(framesA,2), size(framesB,2));
      numCorresp = numBestMatches;
      
      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
      
      obj.info('Repeatability: %g \t Num correspondences: %g',repeatability,numCorresp);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),timeElapsed);
    end
    
    function signature = getSignature(obj)
      import helpers.*;
      signature = struct2str(obj.opts);
    end
    
  end 
    
end

