classdef matchingBenchmark < benchmarks.genericBenchmark & helpers.Logger ...
    & helpers.GenericInstaller
  %MATCHINGBENCHMARK 
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
  %   CropFrames :: [false]
  %   Crop frames out of overlapping regions of image pair.
  %
  %   Magnification :: [3]
  %   Before computing overlaps, magnify the input frames in order to
  %   reflect the size of the region used for descriptor calculation.
  %
  
  properties
    opts                % Local options of matchingTest
  end
  
  properties(Constant)
    defOverlapError = 0.5;
    defNormaliseFrames = false;
    defCropFrames = false;
    defMagnification = 3;
    keyPrefix = 'matching';
    repFramesKeyPrefix = 'reprojectedFrames';
  end
  
  methods
    function obj = matchingBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      obj.benchmarkName = 'matching';
      
      obj.opts.overlapError = matchingBenchmark.defOverlapError;
      obj.opts.normaliseFrames = matchingBenchmark.defNormaliseFrames;
      obj.opts.magnification  = matchingBenchmark.defMagnification;
      obj.opts.cropFrames = matchingBenchmark.defCropFrames;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.benchmarkName,varargin);
      
      if ~obj.isInstalled()
        obj.warn('Benchmark not installed.');
        obj.installDeps();
      end
    end
    
     function [matchingScore numMatches bestMatches reprojFrames] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)

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
        [framesA descriptorsA] = detector.extractFeatures(imageAPath);
        [framesB descriptorsB] = detector.extractFeatures(imageBPath);
      
        [matchingScore numMatches bestMatches reprojFrames] = ... 
          testFeatures(obj,tf, imageAPath, imageBPath, framesA, framesB, ...
          descriptorsA, descriptorsB);
        
        results = {matchingScore numMatches bestMatches reprojFrames };
        
        helpers.DataCache.storeData(results, resultsKey);
      else
        [matchingScore numMatches bestMatches reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end
      
    end
   
    function [matchingScore numMatches bestMatches reprojFrames] = ... 
                testFeatures(obj, tf, imageAPath, imageBPath, ...
                framesA, framesB, descriptorsA, descriptorsB)
      %TESTFEATURES Compute matching score of a given frames and descriptors.
      %  [MATCHING NUM_MATCHES] = testFeatures(TF, IMAGE_A_PATH, 
      %     IMAGE_B_PATH, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B) Compute 
      %     matching score MATCHING between frames FRAMES_A and FRAMES_B 
      %     and their descriptors DESCS_A and DESCS_B which were extracted 
      %     from images defined by their path IMAGEA_PATH and IMAGEB_PATH 
      %     which geometry is related by homography TF. NUM_MATHCES is 
      %     number of matches.
      import benchmarks.helpers.*;
      import helpers.*;
      
      startTime = tic;
      normFrames = obj.opts.normaliseFrames;
      overlErr = obj.opts.overlapError;
      
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;
      
      [reprojFramesA,reprojFramesB] = reprojectFrames(framesA, framesB, tf);

      if obj.opts.cropFrames
        % Get the size of the input images
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
      
      % Compute magnified frames
      magFactor = obj.opts.magnification^2;
      mframesA = [framesA(1:2,:); framesA(3:5,:).*magFactor];
      mreprojFramesB = [reprojFramesB(1:2,:); ...
        reprojFramesB(3:5,:).*magFactor];
      
      % Find all ellipses with sufficient overlap
      obj.info('Computing overlaps between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      frameMatches = fastEllipseOverlap(mreprojFramesB, mframesA,...
        'NormaliseFrames',normFrames);

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
      matches = greedyBipartiteMatching(numFramesA, numFramesB, edges);
      
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
      
      obj.info('Matching score: %g \t Num. of matches: %g',...
        matchingScore,numMatches);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),timeElapsed);
    end
    
    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
  end
  
  
  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer(),benchmarks.helpers.Installer()};
    end
  end
end

