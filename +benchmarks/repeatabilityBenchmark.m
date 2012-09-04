classdef repeatabilityBenchmark < benchmarks.genericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
  % REPEATABILITYBENCHMARK Compute the repeatability of detected features
  %   REPEATABILITYBENCHMARK(resultsStorage,'OptionName',optionValue,...)
  %   constructs an object to compute the repeatabiliy of detected
  %   features.
  %   Repeatability measure can be calculated between two sets of frames
  %   FRMS_A and FRMS_B(descriptors) detected in a pair of images which 
  %   are related by a linear transformation (homography). In ideal case
  %   the frames would be related by the same homography as the images are.
  %   Repeatability express a ratio of frames which fulfill this proportion
  %   to a number of detected frames.
  %   A key is a definition of a match of two frames. Match is a one-to-one
  %   relation between two nodes (frames) in weighted complete bipartite 
  %   graph where the edges can be weighted by overlaps of appropriate
  %   frames (in case of 'MatchFramesGeometry') or by the distances
  %   of their image descriptors ('MatchFramesDescriptors' is true). 
  %   One-to-one matches are calculated using greedy maximum weighted 
  %   matching, i.e. that the closest/max overlaping frames are matched 
  %   first.
  %   When frames are matched both by their geometry and descriptor
  %   distances, two matchings are calculated and their union is deemed as
  %   correct.
  %   The repeatability score is caluclated as:
  %
  %                 numMatches
  %   Score = ----------------------
  %            min(framesA, framesB)
  %
  %   Options:
  %
  %   MatchFramesGeometry :: [true]
  %     Calculate one to one matches based on frames geometry (overlaps).
  %
  %   MatchFramesDescriptors :: [false]
  %     Create one to one matches based on distances of the image
  %     descirptors of frames.
  %
  %   OverlapError:: [0.4]
  %     Maximal overlap error of frames to be considered as 
  %     correspondences.
  %
  %   NormaliseFrames:: [true]
  %     Normalise the frames to constant scale (defaults is true for
  %     detector repeatability tests, see Mikolajczyk et. al 2005).
  %
  %   CropFrames:: [true]
  %     Crop the frames out of overlaping regions (regions present in both 
  %     images).
  %
  %   Magnification :: [3]
  %     When frames are not normalised, this parameter is magnification
  %     applied to the input frames. Usually is equal to magnification
  %     factor used for descriptor calculation.
  %
  %   WarpMethod :: ['standard']
  %     Numerical method used for warping ellipses. Available values are
  %     'standard' and 'km' for precise reproduction of IJCV2005 benchmark
  %     results.
  %

  % AUTORIGHTS

  properties
    opts % Local options of repeatabilityTest
  end

  properties(Constant)
    defOverlapError = 0.4; % Default OverlapError value
    defNormaliseFrames = true;
    defCropFrames = true;
    defMagnification = 3;
    defWarpMethod = 'standard';
    defMatchFramesGeometry = true;
    defMatchFramesDescriptors = false;
    keyPrefix = 'repeatability';
  end

  methods
    function obj = repeatabilityBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      obj.benchmarkName = 'repeatability';
      obj.opts.overlapError = obj.defOverlapError;
      obj.opts.normaliseFrames = obj.defNormaliseFrames;
      obj.opts.magnification  = obj.defMagnification;
      obj.opts.cropFrames = obj.defCropFrames;
      obj.opts.warpMethod = obj.defWarpMethod;
      obj.opts.matchFramesGeometry = obj.defMatchFramesGeometry;
      obj.opts.matchFramesDescriptors = obj.defMatchFramesDescriptors;
      if numel(varargin) > 0
        [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      end
      obj.configureLogger(obj.benchmarkName,varargin);

      if ~obj.isInstalled()
        obj.warn('Benchmark not installed.');
        obj.installDeps();
      end

      if ~obj.opts.matchFramesGeometry && ~obj.opts.matchFramesDescriptors
        obj.error('Invalid options - no way how to match frames.');
      end
    end

    function [score numMatches bestMatches reprojFrames] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)
      %TESTDETECTOR Compute repeatability of a detector.
      %  [SCORE NUM_CORR] = testDetector(DETECTOR, TF, IMAGE_A_PATH,
      %     IMAGE_B_PATH) Compute score of a detector DETECTOR
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
        if obj.opts.matchFramesDescriptors
          % Calculate bot frames and descriptors
          [framesA descriptorsA] = detector.extractFeatures(imageAPath);
          [framesB descriptorsB] = detector.extractFeatures(imageBPath);

          [score numMatches bestMatches reprojFrames] = obj.testFeatures(...
            tf, imageAPath, imageBPath, framesA, framesB,...
            descriptorsA, descriptorsB);
        else
          [framesA] = detector.extractFeatures(imageAPath);
          [framesB] = detector.extractFeatures(imageBPath);

          [score numMatches bestMatches reprojFrames] = ...
            obj.testFeatures(tf,imageAPath, imageBPath,framesA, framesB);
        end

        results = {score numMatches bestMatches reprojFrames };

        helpers.DataCache.storeData(results, resultsKey);
      else
        [score numMatches bestMatches reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end

    end

    function [score numMatches geometryMatches reprojFrames] = ...
                testFeatures(obj, tf, imageAPath, imageBPath, ...
                framesA, framesB, descriptorsA, descriptorsB)
      %TESTFEATURES Compute matching score of a given frames and descriptors.
      %  [SCORE NUM_MATCHES] = testFeatures(TF, IMAGE_A_PATH, 
      %     IMAGE_B_PATH, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B) Compute 
      %     matching score SCORE between frames FRAMES_A and FRAMES_B 
      %     and their descriptors DESCS_A and DESCS_B which were extracted 
      %     from images defined by their path IMAGEA_PATH and IMAGEB_PATH 
      %     which geometry is related by homography TF. NUM_MATHCES is 
      %     number of matches.
      import benchmarks.helpers.*;
      import helpers.*;

      obj.info('Computing score between %d/%d frames.',...
          size(framesA,2),size(framesB,2));

      if exist('descriptorsA','var') && exist('descriptorsB','var')
        if size(framesA,2) ~= size(descriptorsA,2) ...
            || size(framesB,2) ~= size(descriptorsB,2)
          obj.error('Number of frames and descriptors must be the same.');
        end
      elseif obj.opts.matchFramesDescriptors
        obj.error('Unable to match descriptors without descriptors.');
      end

      startTime = tic;
      normFrames = obj.opts.normaliseFrames;
      overlapError = obj.opts.overlapError;
      overlapThresh = 1 - overlapError;

      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;
      
      [reprojFramesA,reprojFramesB] = ...
        obj.reprojectFrames(framesA, framesB,tf);
      
      if obj.opts.cropFrames
        imageA = imread(imageAPath);
        imageB = imread(imageBPath);
        imageASize = size(imageA);
        imageBSize = size(imageB);
        clear imageA;
        clear imageB;

        % find frames fully visible in both images
        bboxA = [1 1 imageASize(2)+1 imageASize(1)+1] ;
        bboxB = [1 1 imageBSize(2)+1 imageBSize(1)+1] ;

        visibleFramesA = isEllipseInBBox(bboxA, framesA ) & ...
          isEllipseInBBox(bboxB, reprojFramesA);

        visibleFramesB = isEllipseInBBox(bboxA, reprojFramesB) & ...
          isEllipseInBBox(bboxB, framesB );

        % Crop frames outside overlap region
        framesA = framesA(:,visibleFramesA);
        reprojFramesA = reprojFramesA(:,visibleFramesA);
        framesB = framesB(:,visibleFramesB);
        reprojFramesB = reprojFramesB(:,visibleFramesB);

        if obj.opts.matchFramesDescriptors
          descriptorsA = descriptorsA(:,visibleFramesA);
          descriptorsB = descriptorsB(:,visibleFramesB);
        end
      end

      if ~normFrames
        % When frames are not normalised, account the descriptor region
        magFactor = obj.opts.magnification^2;
        framesA = [framesA(1:2,:); framesA(3:5,:).*magFactor];
        reprojFramesB = [reprojFramesB(1:2,:); ...
          reprojFramesB(3:5,:).*magFactor];
      end

      numFramesA = size(framesA,2);
      numFramesB = size(reprojFramesB,2);

      % Find all ellipse overlaps (in one-to-n array)
      frameOverlaps = fastEllipseOverlap(reprojFramesB, framesA, ...
        'NormaliseFrames',normFrames,'MinAreaRatio',overlapThresh);

      matches = zeros(0, numFramesA) ;

      if obj.opts.matchFramesGeometry
        % Collect all frame overlaps in a single array ~ edges in a
        % bipartite graph
        corresp = zeros(3,0);
        for j=1:numFramesA
          numNeighs = length(frameOverlaps.scores{j});
          if numNeighs > 0
            corresp = [corresp, ...
                      [j *ones(1,numNeighs); frameOverlaps.neighs{j}; ...
                      frameOverlaps.scores{j}]];
          end
        end

        % Remove edges with unsufficient overlap
        corresp = corresp(:,corresp(3,:)>overlapThresh);

        % Create ranked list of edges based on the overlap
        [drop, perm] = sort(corresp(3,:), 'descend');
        corresp = corresp(:, perm);

        % Find on-to-one best matches based on frames geometry
        obj.info('Matching frames geometry.');
        geometryMatches = greedyBipartiteMatching(numFramesA,...
          numFramesB, corresp(1:2,:)');

        matches = [matches ; geometryMatches];
      end

      if obj.opts.matchFramesDescriptors
        obj.info('Computing cross distances between all descriptors');
        dists = vl_alldist2(single(descriptorsA),single(descriptorsB));
        obj.info('Sorting distances')
        [dists, perm] = sort(dists(:),'ascend');

        % Create list of edges in the bipartite graph
        [aIdx bIdx] = ind2sub([numFramesA, numFramesB],perm(1:numel(dists)));
        edges = [aIdx bIdx];

        % Find one-to-one best matches
        obj.info('Matching descriptors.');
        descMatches = greedyBipartiteMatching(numFramesA, numFramesB, edges);

        for aIdx=1:numFramesA
          bIdx = descMatches(aIdx);
          [hasCorresp bCorresp] = ismember(bIdx,frameOverlaps.neighs{aIdx});
          % Check whether found descriptor matches fulfill frame overlap
          if ~hasCorresp || ...
             ~frameOverlaps.scores{aIdx}(bCorresp) > overlapThresh
            descMatches(aIdx) = 0;
          end
        end
        matches = [matches ; descMatches];
      end

      % Combine collected matches, i.e. select only equal matches
      validMatches = ...
        prod(single(matches == repmat(matches(1,:),size(matches,1),1)),1);
      matches = matches(1,validMatches~=0);

      % Compute the score
      numBestMatches = sum(matches ~= 0);
      score = numBestMatches / min(size(framesA,2), size(framesB,2));
      numMatches = numBestMatches;

      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};

      obj.info('Score: %g \t Num matches: %g', ...
        score,numMatches);

      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),toc(startTime));
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end

  end

  methods (Access = protected)
    function [reprojFramesA reprojFramesB] = reprojectFrames(obj, ...
        framesA, framesB, tfs)
      % REPROJECTFRAMES Reproject frames detected in images pair
      %   through homography.
      %   [REP_FRAMES_A REP_FRAMES_B] = reprojectFrames(FRAMES_A, FRAMES_B,
      %      TF) Reproject FRAMES_A to REP_FRAMES_A using homography TF 
      %      and FRAMES_B to REP_FRAMES_B with homography inv(TF). Before 
      %      reprojection frames are converted to 0-starting coordinates.
      import benchmarks.helpers.*;

      % Change from Matlab origin
      framesA(1:2,:) = framesA(1:2,:) - 1 ;
      framesB(1:2,:) = framesB(1:2,:) - 1 ;

      % Reproject
      reprojFramesA = warpEllipse(tfs,framesA, ...
        'Method', obj.opts.warpMethod) ;
      reprojFramesB = warpEllipse(inv(tfs),framesB, ...
        'Method', obj.opts.warpMethod) ;

      % Move reprojected frames back to Matlab origin
      reprojFramesA(1:2,:) = reprojFramesA(1:2,:) + 1 ;
      reprojFramesB(1:2,:) = reprojFramesB(1:2,:) + 1 ;
    end
  end

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer(),helpers.VlFeatInstaller(),...
        benchmarks.helpers.Installer()};
    end
  end

end

