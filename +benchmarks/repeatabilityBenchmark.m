classdef repeatabilityBenchmark < benchmarks.genericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
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
  %   CropFrames :: [true]
  %   Crop the frames out of overlaping regions.
  %
  
  properties
    opts                % Local options of repeatabilityTest
  end
  
  properties(Constant)
    defOverlapError = 0.4; % Default OverlapError value
    defNormaliseFrames = true;
    defCropFrames = true;
    keyPrefix = 'repeatability';
    reprojFramesKeyPrefix = 'reprojectedFrames';
  end
  
  methods
    function obj = repeatabilityBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      obj.benchmarkName = 'repeatability';
      
      obj.opts.overlapError = repeatabilityBenchmark.defOverlapError;
      obj.opts.normaliseFrames = repeatabilityBenchmark.defNormaliseFrames;
      obj.opts.cropFrames = repeatabilityBenchmark.defCropFrames;
      if numel(varargin) > 0
        [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      end
      obj.configureLogger(obj.benchmarkName,varargin);
      
      if ~obj.isInstalled()
        obj.warn('Benchmark not installed.');
        obj.installDeps();
      end
    end
    
    function [repeatability numCorresp bestCorresp reprojFrames] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)
      %TESTDETECTOR Compute repeatability of a detector.
      %  [REP NUM_CORR] = testDetector(DETECTOR, TF, IMAGE_A_PATH, 
      %     IMAGE_B_PATH) Compute repeatability REP of a detector DETECTOR 
      %     and its frames extracted from images defined by their path 
      %     IMAGEA_PATH and IMAGEB_PATH which geometry is related by 
      %     homography TF. NUM_CORR is number of found correspondences.
      %     This method caches its results.
      import benchmarks.*;
      import helpers.*;
      
      obj.info('Comparing frames from det. %s and images %s and %s.',...
          detector.detectorName,getFileName(imageAPath),...
          getFileName(imageBPath));
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      resultsKey = cell2str({obj.keyPrefix, obj.getSignature(), ...
        detector.getSignature(), imageASign, imageBSign});
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        [framesA] = detector.extractFeatures(imageAPath);
        [framesB] = detector.extractFeatures(imageBPath);
      
        [repeatability numCorresp bestCorresp reprojFrames] = ... 
          testFeatures(obj,tf,imageAPath, imageBPath,framesA, framesB);
        
        results = {repeatability numCorresp bestCorresp reprojFrames };
        
        helpers.DataCache.storeData(results, resultsKey);
      else
        [repeatability numCorresp bestCorresp reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end
      
    end
   
    function [repeatability numCorresp bestCorresp reprojFrames] = ... 
                testFeatures(obj, tf, imageAPath, imageBPath, framesA, framesB)
      %TESTFEATURES Compute repeatability of a given frames.
      %  [REP NUM_CORR] = testFeatures(TF, IMAGE_A_PATH, 
      %     IMAGE_B_PATH, FRAMES_A, FRAMES_B) Compute repeatability 
      %     REP between frames FRAMES_A and FRAMES_B which were extracted 
      %     from images defined by their path IMAGEA_PATH and IMAGEB_PATH 
      %     which geometry is related by homography TF. NUM_CORR is number 
      %     of found correspondences.
      import benchmarks.helpers.*;
      import helpers.*;
      
      obj.info('Computing repeatability between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      
      startTime = tic;
      normFrames = obj.opts.normaliseFrames;
      overlapError = obj.opts.overlapError;
      overlapThresh = 1 - overlapError;
      
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;
      
      [reprojFramesA,reprojFramesB] = reprojectFrames(framesA, framesB, tf);
      
      if obj.opts.cropFrames
        imageA = imread(imageAPath);
        imageB = imread(imageBPath);
        imageASize = size(imageA);
        imageBSize = size(imageB);
        clear imageA;
        clear imageB;

        % find frames fully visible in both images
        bboxA = [1 1 imageASize(2) imageASize(1)] ;
        bboxB = [1 1 imageBSize(2) imageBSize(1)] ;

        visibleFramesA = isEllipseInBBox(bboxA, framesA ) & ...
          isEllipseInBBox(bboxB, reprojFramesA);

        visibleFramesB = isEllipseInBBox(bboxA, reprojFramesB) & ...
          isEllipseInBBox(bboxB, framesB );

        % Crop frames outside overlap region
        framesA = framesA(:,visibleFramesA);
        reprojFramesA = reprojFramesA(:,visibleFramesA);
        framesB = framesB(:,visibleFramesB);
        reprojFramesB = reprojFramesB(:,visibleFramesB);
      end

      % Find all ellipse correspondences
      frameCorresp = fastEllipseOverlap(reprojFramesB, framesA, ...
        'NormaliseFrames',normFrames,'MinAreaRatio',overlapThresh - 0.1);
      
      % Find the best one-to-one correspondences
      numFramesA = size(framesA,2);
      numFramesB = size(reprojFramesB,2);
      corresp = zeros(3,0);
      bestCorresp = zeros(2, numFramesA) ;

      % Collect all correspondences in a single array
      for j=1:numFramesA
        numNeighs = length(frameCorresp.scores{j});
        if numNeighs > 0
          corresp = [corresp, ...
                    [j *ones(1,numNeighs); frameCorresp.neighs{j}; ...
                    frameCorresp.scores{j}]];
        end
      end

      % Filter corresp. with insufficient overlap
      corresp = corresp(:,corresp(3,:)>overlapThresh);

      % eliminate assigment by priority, i.e. sort the corresp by the score
      [drop, perm] = sort(corresp(3,:), 'descend');
      corresp = corresp(:, perm);

      % Find on-to-one best correspondences
      bestCorresp(1,:) = greedyBipartiteMatching(numFramesA, numFramesB, ...
        corresp(1:2,:)');

      % Collect the overlaps
      for i=1:numFramesA
        bidx = bestCorresp(1,i);
        if bidx ~= 0
          bestCorresp(2,i) = corresp(1,corresp(1,:)==i & corresp(2,:)== bidx);
        end
      end
      
      numBestMatches = sum(bestCorresp(1,:) ~= 0);
      repeatability = numBestMatches / min(size(framesA,2), size(framesB,2));
      numCorresp = numBestMatches;
      
      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
      
      obj.info('Repeatability: %g \t Num correspondences: %g', ...
        repeatability,numCorresp);
      
      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),toc(startTime));
    end
    
    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
    
  end
    
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer(),helpers.VlFeatInstaller(),...
        benchmarks.helpers.Installer()};
    end
  end
  
end

