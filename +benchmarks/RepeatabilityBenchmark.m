classdef RepeatabilityBenchmark < benchmarks.GenericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
% benchmarks.RepeatabilityBenchmark Image features repeatability
%   benchmarks.RepeatabilityBenchmark('OptionName',optionValue,...) constructs
%   an object to compute the detector repeatability and the descriptor
%   matching scores as given in [1].
%
%   Using this class is a two step process. First, create an instance of the
%   class specifying any parameter needed in the constructor. Then, use
%   obj.testFeatures() to evaluate the scores given a pair of images, the
%   detected features (and optionally their descriptors), and the homography
%   between the two images.
%
%   Use obj.testFeatureExtractor() to evaluate the test for a given detector
%   and pair of images and being able to cache the results of the test.
%
%   DETAILS ON THE REPEATABILITY AND MATCHING SCORES
%
%   The detector repeatability is calculated for two sets of feature frames
%   FRAMESA and FRAMESB detected in a reference image IMAGEA and a second
%   image IMAGEB. The two images are assumed to be related by a known
%   homography H mapping pixels in the domain of IMAGEA to pixels in the
%   domain of IMAGEB (e.g. static camera, no parallax, or moving camera
%   looking at a flat scene). The homography assumes image coordinates with
%   origin in (0,0).
%
%   A perfect co-variant detector would detect the same features in both
%   images regardless of a change in viewpoint (for the features that are
%   visible in both cases). A good detector will also be robust to noise and
%   other distortion. Repeatability is the percentage of detected features
%   that survive a viewpoint change or some other transformation or
%   disturbance in going from IMAGEA to IMAGEB.
%
%   More in detail, repeatability is by default computed as follows:
%
%   1. The elliptical or circular feature frames FRAMEA and FRAMEB,
%      the image sizes SIZEA and SIZEB, and the homography H are
%      obtained.
%
%   2. Features (ellipses or circles) that are fully visible in both
%      images are retained and the others discarded.
%
%   3. For each pair of feature frames A and B, the normalised overlap
%      measure OVERLAP(A,B) is computed. This is defined as the ratio
%      of the area of the intersection over the area of the union of
%      the ellpise/circle FRAMESA(:,A) and FRAMES(:,B) reprojected on
%      IMAGEA by the homography H. Furthermore, after reprojection the
%      size of the ellpises/circles are rescaled so that FRAMESA(:,A)
%      has an area equal to the one of a circle of radius 30 pixels.
%
%   4. Feature are matched optimistically. A candidate match (A,B) is
%      created for every pair of features A,B such that the
%      OVELRAP(A,B) is larger than a certain threshold (defined as 1 -
%      OverlapError) and weighted by OVERLAP(A,B). Then, the final set
%      of matches M={(A,B)} is obtained by performing a greedy
%      bipartite matching between in the weighted graph
%      thus obtained. Greedy means that edges are assigned in order
%      of decreasing overlap.
%
%   5. Repeatability is defined as the ratio of the number of matches
%      M thus obtained and the minimum of the number of features in
%      FRAMESA and FRAMESB:
%
%                                    |M|
%        repeatability = -------------------------.
%                        min(|framesA|, |framesB|)
%
%   RepeatabilityBenchmark can compute the descriptor matching score
%   too (see the 'Mode' option). To define this, a second set of 
%   matches M_d is obtained similarly to the previous method, except 
%   that the descriptors distances are used in place of the overlap, 
%   no threshold is involved in the generation of candidate matches, and 
%   these are selected by increasing descriptor distance rather than by
%   decreasing overlap during greedy bipartite matching. Then the
%   descriptor matching score is defined as:
%
%                              |inters(M,M_d)|
%        matching-score = -------------------------.
%                         min(|framesA|, |framesB|)
%
%   The test behaviour can be adjusted by modifying the following options:
%
%   Mode:: 'Repeatability'
%     Type of score to be calculated. Changes the criteria which are used
%     for finding one-to-one matches between image features.
%
%     'Repeatability'
%       Match frames geometry only. 
%       Corresponds to detector repeatability measure in [1].
%
%     'MatchingScore'
%       Match frames geometry and frame descriptors.
%       Corresponds to detector matching score in [1].
%
%     'DescMatchingScore'
%        Match frames only based on their descriptors.
%
%   DescriptorsDistanceMetric:: 'L2'
%     Distance metric used for matching the descriptors. See
%     documentation of vl_alldist2 for details.
%
%   See also: datasets.VggAffineDataset, vl_alldist2
%
%   REFERENCES
%   [1] K. Mikolajczyk, T. Tuytelaars, C. Schmid, A. Zisserman,
%       J. Matas, F. Schaffalitzky, T. Kadir, and L. Van Gool. A
%       comparison of affine region detectors. IJCV, 1(65):43–72, 2005.

% Authors: Karel Lenc, Andrea Vedaldi

% AUTORIGHTS

  properties
    Opts = struct(...
      'mode', 'repeatability',...
      'descriptorsDistanceMetric', 'L2' ...
      );
    ConsistencyModel;
  end

  properties(Constant, Hidden)
    KeyPrefix = 'repeatability';
    %
    Modes = {'repeatability','matchingscore','descmatchingscore'};
    ModesOpts = containers.Map(benchmarks.RepeatabilityBenchmark.Modes,...
      {struct('matchGeometry',true,'matchDescs',false),...
      struct('matchGeometry',true,'matchDescs',true),...
      struct('matchGeometry',false,'matchDescs',true)});
  end

  methods
    function obj = RepeatabilityBenchmark(consistencyModel, varargin)
      import benchmarks.*;
      import helpers.*;
      obj.BenchmarkName = 'repeatability';
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      if numel(varargin) > 0
        obj.Opts = vl_argparse(obj.Opts,varargin);
        obj.Opts.mode = lower(obj.Opts.mode);
        if ~ismember(obj.Opts.mode, obj.Modes)
          error('Invalid mode %s.',obj.Opts.mode);
        end
      end
      obj.ConsistencyModel = consistencyModel;
    end

    function [score numMatches subsres] = ...
        testFeatureExtractor(obj, featExtractor, sceneGeometry, ...
        imageAPath, imageBPath)
      % testFeatureExtractor Image feature extractor repeatability
      %   REPEATABILITY = obj.testFeatureExtractor(FEAT_EXTRACTOR, TF,
      %   IMAGEAPATH, IMAGEBPATH) computes the repeatability REP of a image
      %   feature extractor FEAT_EXTRACTOR and its frames extracted from
      %   images defined by their path IMAGEAPATH and IMAGEBPATH whose
      %   geometry is related by the homography transformation TF.
      %   FEAT_EXTRACTOR must be a subclass of
      %   localFeatures.GenericLocalFeatureExtractor.
      %
      %   [REPEATABILITY, NUMMATCHES] = obj.testFeatureExtractor(...) 
      %   returns also the total number of feature matches found.
      %
      %   [REP, NUMMATCHES, REPR_FRAMES, MATCHES] =
      %   obj.testFeatureExtractor(...) returns cell array REPR_FRAMES which
      %   contains reprojected and eventually cropped frames in
      %   format:
      %
      %   REPR_FRAMES = {CFRAMES_A,CFRAMES_B,REP_CFRAMES_A,REP_CFRAMES_B}
      %
      %   where CFRAMES_A are (cropped) frames detected in the IMAGEAPATH
      %   image REP_CFRAMES_A are CFRAMES_A reprojected to the IMAGEBPATH
      %   image using homography TF. Same hold for frames from the secons
      %   image CFRAMES_B and REP_CFRAMES_B.
      %   MATCHES is an array of size [size(CFRAMES_A),1]. Two frames are
      %   CFRAMES_A(k) and CFRAMES_B(l) are matched when MATCHES(k) = l.
      %   When frame CFRAMES_A(k) is not matched, MATCHES(k) = 0.
      %
      %   This method caches its results, so that calling it again will not
      %   recompute the repeatability score unless the cache is manually
      %   cleared.
      %
      %   See also: benchmarks.RepeatabilityBenchmark().
      import benchmarks.*;
      import helpers.*;

      obj.info('Comparing frames from det. %s and images %s and %s.',...
          featExtractor.Name,getFileName(imageAPath),...
          getFileName(imageBPath));

      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      resultsKey = cell2str({obj.KeyPrefix, obj.getSignature(), ...
        featExtractor.getSignature(), imageASign, imageBSign});
      cachedResults = obj.loadResults(resultsKey);

      % When detector does not cache results, do not use the cached data
      if isempty(cachedResults) || ~featExtractor.UseCache
        if obj.ModesOpts(obj.Opts.mode).matchDescs
          [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
          [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
          [score numMatches subsres] = obj.testFeatures(...
            sceneGeometry, framesA, framesB, descriptorsA, descriptorsB);
        else
          [framesA] = featExtractor.extractFeatures(imageAPath);
          [framesB] = featExtractor.extractFeatures(imageBPath);
          [score numMatches subsres] = ...
            obj.testFeatures(sceneGeometry, framesA, framesB);
        end
        if featExtractor.UseCache
          results = {score numMatches subsres};
          obj.storeResults(results, resultsKey);
        end
      else
        [score numMatches subsres] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end

    end

    function [score numMatches subsres] = ...
        testFeatures(obj, sceneGeometry, framesA, framesB, ...
        descriptorsA, descriptorsB)
      % testFeatures Compute repeatability of given image features
      %   [SCORE NUM_MATCHES] = obj.testFeatures(TF, IMAGE_A_SIZE,
      %   IMAGE_B_SIZE, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B) Compute
      %   matching score SCORE between frames FRAMES_A and FRAMES_B
      %   and their descriptors DESCS_A and DESCS_B which were
      %   extracted from pair of images with sizes IMAGE_A_SIZE and
      %   IMAGE_B_SIZE which geometry is related by homography TF.
      %   NUM_MATHCES is number of matches which is calcuated
      %   according to object settings.
      %
      %   [SCORE, NUM_MATCHES, REPR_FRAMES, MATCHES] =
      %   obj.testFeatures(...) returns cell array REPR_FRAMES which
      %   contains reprojected and eventually cropped frames in
      %   format:
      %
      %   REPR_FRAMES = {CFRAMES_A,CFRAMES_B,REP_CFRAMES_A,REP_CFRAMES_B}
      %
      %   where CFRAMES_A are (cropped) frames detected in the IMAGEAPATH
      %   image REP_CFRAMES_A are CFRAMES_A reprojected to the IMAGEBPATH
      %   image using homography TF. Same hold for frames from the secons
      %   image CFRAMES_B and REP_CFRAMES_B.
      %   MATCHES is an array of size [size(CFRAMES_A),1]. Two frames are
      %   CFRAMES_A(k) and CFRAMES_B(l) are matched when MATCHES(k) = l.
      %   When frame CFRAMES_A(k) is not matched, MATCHES(k) = 0.
      import benchmarks.helpers.*;
      import helpers.*;

      obj.info('Computing score between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      matchGeometry = obj.ModesOpts(obj.Opts.mode).matchGeometry;
      matchDescriptors = obj.ModesOpts(obj.Opts.mode).matchDescs;
      
      score = 0; numMatches = 0; matches = []; subsres = struct();
      
      if isempty(framesA) || isempty(framesB)
        obj.info('Nothing to compute.');
        return;
      end
      if exist('descriptorsA','var') && exist('descriptorsB','var')
        if size(framesA,2) ~= size(descriptorsA,2) ...
            || size(framesB,2) ~= size(descriptorsB,2)
          obj.error('Number of frames and descriptors must be the same.');
        end
      elseif matchDescriptors
        obj.error('Unable to match descriptors without descriptors.');
      end

      startTime = tic;
      [correspondences consistency subsres] = ...
        obj.ConsistencyModel.findConsistentCorresps(sceneGeometry, framesA, framesB);
      
      if isempty(correspondences), return; end;
      
      if isfield(subsres,'validFramesA') && isfield(subsres,'validFramesB')
        framesA = framesA(:,subsres.validFramesA);
        framesB = framesB(:,subsres.validFramesB);
        if nargin > 4 
          descriptorsA = descriptorsA(:,subsres.validFramesA);
          descriptorsB = descriptorsB(:,subsres.validFramesB);
        end
      end
      
      numFramesA = size(framesA,2);
      numFramesB = size(framesB,2);
      
      % Create indexes of positive values in incidence matrix
      validCorrespIdxs = sub2ind([numFramesA, numFramesB], ...
        correspondences(1,:), correspondences(2,:));

      if matchGeometry
        % Sort the edgest by decrasing score
        [drop, perm] = sort(consistency, 'descend');
        sortedCorresp = correspondences(:, perm);

        % Approximate the best bipartite matching
        obj.info('Matching frames geometry.');
        geometryMatches = greedyBipartiteMatching(numFramesA,...
          numFramesB, sortedCorresp');

        subsres.geometryMatches = geometryMatches;
        matches = [matches ; geometryMatches];
      end

      if matchDescriptors
        matcher = benchmarks.helpers.DataMatcher('matchStrategy','1to1',...
          'distMetric',obj.Opts.descriptorsDistanceMetric);

        matchEdges = matcher.matchData(descriptorsB, descriptorsA);

        % Idxs of matches in incidence matrix
        matchesIdxs = sub2ind([numFramesA, numFramesB], ...
          matchEdges(2,:), matchEdges(1,:));
        
        % Find matches with sufficient overlap
        [drop validMatch] = intersect(matchesIdxs, validCorrespIdxs);
        
        descMatches = zeros(1,numFramesA);
        descMatches(matchEdges(2,validMatch)) = matchEdges(1,validMatch);
        subsres.descMatches = descMatches;
        matches = [matches ; descMatches];
      end

      % Combine collected matches, i.e. select only equal matches
      validMatches = ...
        prod(single(matches == repmat(matches(1,:),size(matches,1),1)),1);
      matches = matches(1,:) .* validMatches;
      subsres.matches = matches;

      % Compute the score
      numMatches = sum(matches ~= 0);
      score = numMatches / min(size(framesA,2), size(framesB,2));

      obj.info('Score: %g \t Num matches: %g', score,numMatches);

      obj.debug('Score between %d/%d frames comp. in %gs',...
        size(framesA,2), size(framesB,2),toc(startTime));
    end

    function signature = getSignature(obj)
      signature = [helpers.struct2str(obj.Opts) ...
        obj.ConsistencyModel.getSignature()];
    end
  end

end

