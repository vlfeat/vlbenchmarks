classdef repeatabilityBenchmark < benchmarks.genericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
% REPEATABILITYBENCHMARK evaluates the repeatability and matching scores of features
%   REPEATABILITYBENCHMARK(resultsStorage,'OptionName',optionValue,...)
%   constructs an object to compute the repeatabiliy and matching
%   scores [1] of detected features.
%
%   DETAILS ON THE REPEATABILITY AND MATCHING SCORE MEASURES
%
%   The repeatability measure is calculated for two sets of feature
%   frames FRAMESA and FRAMESB detected in a reference image IMAGEA
%   and a second image IMAGEB. The two images are assumed to be
%   related by a known homography H mapping pixels in the domain of
%   IMAGEA to pixels in the domain of IMAGEB (e.g. static camera, no
%   parallax, or moving camera looking at a flat scene).
%
%   ** WHAT CONVENTION IS USED BY THE HOMOGRAPHY? DOES IT ASSUMES
%   (1,1) AS ORIGIN OR (0,0) ? **
%
%   A perfect co-variant detectior would detect the same features in
%   both images regardless of a change in viewpoint (for the features
%   that are visible in both cases). A good detector would also be
%   robust to noise and other distortion. Repeatability is the
%   percentage of detected features that survive a viewpoint change or
%   some other alteration of the image.
%
%   More in detail, repeatability is by default computed as follows:
%
%   1. The elliptical or circular feature frames FRAMEA and FRAMEB,
%      the image sizes SIZEA and SIZEB, and the homography H are given
%      as input.
%
%   2. Only features (ellipses or circles) that are fully visible in
%      both images are retained. This tests whether a feature is
%      contained in the images where it is detected as well as in the
%      other image once reprojected by the homography.
%
%   3. For each pair of feature frames A and B, the normalised
%      overlap measure OVERLAP(A,B) is computed. This is defined as
%      the ratio of the area of the intersection over the area of
%      the union of the ellpise/circle FRAMESA(:,A) and FRAMES(:,B)
%      reprojected on IMAGEA by the homography H. Furthermore,
%      after reprojection the size of the ellpises/circles are
%      rescaled so that FRAMESA(:,A) has an area of 30^2 pixels.
%
%   4. Feature are matched optimistically. A pair of features (A,B) is
%      considered as a candidate match if OVERLAP(A,B) is larger than
%      a threshold of 0.6. Then, a final set of matches M={(A,B)} is
%      selected by performing a greedy bypartite matching between the
%      two sets of features. This means that each feature in IMAGEA
%      can be matched to at most anoter feature in IMAGEB, and matches
%      are selected in order of decreasing OVERLAP(A,B).
%
%   5. Repeatability is defined as the ratio of the number of
%      matches M and the minimum of the number of features in
%      FRAMESA and FRAMESB:
%
%                                    |M|
%        repeatability = -------------------------.
%                        min(|framesA|, |framesB|)
%
%   The class also compute the descriptor matching score (see the
%   'MatchFramesGeometry' and 'MatchFramesDescriptors'
%   options). This is defined in a similar way, except that:
%
%   1. All pairs of feature descriptors are considered, their
%      distances DIST(DESCRA(:,A),DESCRB(:,B)) are computed, and a set
%      of bipartite matches M={(A,B)} is greedly formed by increasing
%      descriptor distance.
%
%   2. From the matches M, the ones for which OVERLAP(A,P) is below
%      the 0.6 threshold are removed.
%
%   3. Given M, the matching score is defined as the repeatability.
%
%   The test behaviour can be adjusted by modifying the following options:
%
%   MatchFramesGeometry:: true
%     Calculate one to one matches based on frames geometry (overlaps).
%
%   MatchFramesDescriptors:: false
%     Create one to one matches based on distances of the image
%     descirptors of frames.
%
%   OverlapError:: 0.4
%     Maximal overlap error of frames to be considered as
%     correspondences.
%
%   NormaliseFrames:: true
%     Normalise the frames to constant scale (defaults is true for
%     detector repeatability tests, see Mikolajczyk et. al 2005).
%
%   CropFrames:: true
%     Crop the frames out of overlaping regions (regions present in both
%     images).
%
%   Magnification:: 3
%     When frames are not normalised, this parameter is magnification
%     applied to the input frames. Usually is equal to magnification
%     factor used for descriptor calculation.
%
%   WarpMethod:: 'standard'
%     Numerical method used for warping ellipses. Available values are
%     'standard' and 'km' for precise reproduction of IJCV2005 benchmark
%     results.
%
%   DescriptorsDistanceMetric:: 'L2'
%     Distance metric used for matching the descriptors. See
%     documentation of VL_ALLDIST2() for details.
%
%   REFERENCES
%   [1] K. Mikolajczyk, T. Tuytelaars, C. Schmid, A. Zisserman,
%       J. Matas, F. Schaffalitzky, T. Kadir, and L. Van Gool. A
%       comparison of affine region detectors. IJCV, 1(65):43–72, 2005.

% Author: Karel Lenc, Andrea Vedaldi

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
    defDescriptorsDistanceMetric = 'L2';
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
      obj.opts.descriptorsDistanceMetric = obj.defDescriptorsDistanceMetric;
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
      % TESTDETECTOR Computes the repeatability of a detector on a pair of images
      %   REPEATABILITY = TESTDETECTOR(DETECTOR, TF, IMAGEAPATH, IMAGEBPATH)
      %   computes the repeatability REP of a detector DETECTOR and its
      %   frames extracted from images defined by their path IMAGEAPATH and
      %   IMAGEBPATH whose geometry is related by the homography
      %   transformation TF.
      %
      %   [REPEATABILITY, NUMMATCHES] = TESTDETECTOR(...) returns also the
      %   total number of feature matches found.
      %
      %   This method caches its results, so that calling it again will not
      %   recompute the repeatability score unless the cache is manually
      %   cleared.
      %
      %   See also: REPEATABILITYBENCHMARK().
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

    function [score numMatches matches reprojFrames] = ...
                testFeatures(obj, tf, imageAPath, imageBPath, ...
                framesA, framesB, descriptorsA, descriptorsB)
      % TESTFEATURES Compute matching score of a given frames and descriptors.
      %   [SCORE NUM_MATCHES] = TESTFEATURES(TF, IMAGE_A_PATH, IMAGE_B_PATH,
      %   FRAMES_A, FRAMES_B, DESCS_A, DESCS_B) Compute matching score
      %   SCORE between frames FRAMES_A and FRAMES_B and their
      %   descriptors DESCS_A and DESCS_B which were extracted from
      %   images defined by their path IMAGEA_PATH and IMAGEB_PATH
      %   which geometry is related by homography TF. NUM_MATHCES is
      %   number of matches.
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

      % map
      reprojFramesA = warpEllipse(tf, framesA,...
        'Method',obj.opts.warpMethod) ;
      reprojFramesB = warpEllipse(inv(tf), framesB,...
        'Method',obj.opts.warpMethod) ;

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
        corresp = cell(1,numFramesA);
        for j=1:numFramesA
          numNeighs = length(frameOverlaps.scores{j});
          if numNeighs > 0
            corresp{j} = [j *ones(1,numNeighs); frameOverlaps.neighs{j};...
              frameOverlaps.scores{j}];
          end
        end
        corresp = cat(2,corresp{:}) ;

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
        dists = vl_alldist2(single(descriptorsA),single(descriptorsB),...
          obj.opts.descriptorsDistanceMetric);
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

  methods (Static)
    function deps = getDependencies()
      deps = {helpers.Installer(),helpers.VlFeatInstaller(),...
        benchmarks.helpers.Installer()};
    end
  end

end

