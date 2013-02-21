classdef DTURobotRepeatabilityBenchmark < benchmarks.GenericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller

  properties
    Opts = struct(...
      'overlapError', 0.4,...
      'normaliseFrames', true,...
      'cropFrames', true,...
      'magnification', 3,...
      'warpMethod', 'linearise',...
      'mode', 'repeatability',...
      'descriptorsDistanceMetric', 'L2',...
      'normalisedScale', 30);
  end

  properties(Constant, Hidden)
    KeyPrefix = 'repeatability3d';
    Modes = {'repeatability','matchingscore','descmatchingscore'};
    ModesOpts = containers.Map(benchmarks.DTURobotRepeatabilityBenchmark.Modes,...
      {struct('matchGeometry',true,'matchDescs',false),...
      struct('matchGeometry',true,'matchDescs',true),...
      struct('matchGeometry',false,'matchDescs',true)});
  end

  methods
    function obj = DTURobotRepeatabilityBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      obj.BenchmarkName = 'repeatability';
      if numel(varargin) > 0
        [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
        obj.Opts.mode = lower(obj.Opts.mode);
        if ~ismember(obj.Opts.mode, obj.Modes)
          error('Invalid mode %s.',obj.Opts.mode);
        end
      end
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end

    function [score numMatches bestMatches reprojFrames] = ...
        testFeatureExtractor(obj, featExtractor, dataset, imageAId, imageBId)
      % testFeatureExtractor Image feature extractor repeatability
      %   REPEATABILITY = obj.testFeatureExtractor(FEAT_EXTRACTOR, TF,
      %   IMAGEAPATH, IMAGEBPATH) computes the repeatability REP of a image
      %   feature extractor FEAT_EXTRACTOR and its frames extracted from
      %   images defined by their path IMAGEAPATH and IMAGEBPATH whose
      %   geometry is related by the homography transformation TF. TODO tf => gtc=ground truth correspondences
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

      imageAPath = dataset.getImagePath(imageAId);
      imageBPath = dataset.getImagePath(imageBId);
      obj.info('Comparing frames from det. %s and images %s and %s.',...
          featExtractor.Name,getFileName(imageAPath),...
          getFileName(imageBPath));

      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      imageASize = helpers.imageSize(imageAPath);
      imageBSize = helpers.imageSize(imageBPath);
      resultsKey = cell2str({obj.KeyPrefix, obj.getSignature(), ...
        featExtractor.getSignature(), imageASign, imageBSign});
      cachedResults = obj.loadResults(resultsKey);

      % When detector does not cache results, do not use the cached data
%      if isempty(cachedResults) || ~featExtractor.UseCache
        if obj.ModesOpts(obj.Opts.mode).matchDescs
          [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
          [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
          [score numMatches bestMatches reprojFrames] = obj.testFeatures(...
            dataset, imageAId, imageBId, imageASize, imageBSize, framesA, framesB,...
            descriptorsA, descriptorsB);
        else
          [framesA] = featExtractor.extractFeatures(imageAPath);
          [framesB] = featExtractor.extractFeatures(imageBPath);
          [score numMatches bestMatches reprojFrames] = ...
            obj.testFeatures(dataset, imageAId, imageBId, imageASize, imageBSize, framesA, framesB);
        end
        if featExtractor.UseCache
          results = {score numMatches bestMatches reprojFrames};
          obj.storeResults(results, resultsKey);
        end
%      else
%        [score numMatches bestMatches reprojFrames] = cachedResults{:};
%        obj.debug('Results loaded from cache');
%      end

    end

    function [score numMatches matches reprojFrames] = ...
        testFeatures(obj, dataset, imageAId, imageBId, imageASize, imageBSize, framesA, framesB, ...
        descriptorsA, descriptorsB)
      % testFeatures Compute repeatability of given image features
      %   [SCORE NUM_MATCHES] = obj.testFeatures(TF, IMAGE_A_SIZE,
      %   IMAGE_B_SIZE, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B) Compute
      %   matching score SCORE between frames FRAMES_A and FRAMES_B
      %   and their descriptors DESCS_A and DESCS_B which were
      %   extracted from pair of images with sizes IMAGE_A_SIZE and
      %   IMAGE_B_SIZE which geometry is related by homography TF.TODO tf=> gtc
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

      if isempty(framesA) || isempty(framesB)
        matches = zeros(size(framesA,2)); reprojFrames = {};
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

      score = 0; numMatches = 0;
      startTime = tic;
      normFrames = obj.Opts.normaliseFrames;
      overlapError = obj.Opts.overlapError;
      overlapThresh = 1 - overlapError;

      % convert frames from any supported format to unortiented
      % ellipses for uniformity
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;

      % map frames from image A to image B and viceversa
%      reprojFramesA = warpEllipse(tf, framesA,...
%        'Method',obj.Opts.warpMethod) ;
%      reprojFramesB = warpEllipse(inv(tf), framesB,...
%        'Method',obj.Opts.warpMethod) ;
%      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
      reprojFrames = {framesA,framesB,framesB, framesA};

%      % optionally remove frames that are not fully contained in
%      % both images
%      if obj.Opts.cropFrames
%        % find frames fully visible in both images
%        bboxA = [1 1 imageASize(2)+1 imageASize(1)+1] ;
%        bboxB = [1 1 imageBSize(2)+1 imageBSize(1)+1] ;

%        visibleFramesA = isEllipseInBBox(bboxA, framesA ) & ...
%          isEllipseInBBox(bboxB, reprojFramesA);

%        visibleFramesB = isEllipseInBBox(bboxA, reprojFramesB) & ...
%          isEllipseInBBox(bboxB, framesB );

%        % Crop frames outside overlap region
%        framesA = framesA(:,visibleFramesA);
%        reprojFramesA = reprojFramesA(:,visibleFramesA);
%        framesB = framesB(:,visibleFramesB);
%        reprojFramesB = reprojFramesB(:,visibleFramesB);
%        if isempty(framesA) || isempty(framesB)
%          matches = zeros(size(framesA,2)); reprojFrames = {};
%          return;
%        end

%        if matchDescriptors
%          descriptorsA = descriptorsA(:,visibleFramesA);
%          descriptorsB = descriptorsB(:,visibleFramesB);
%        end
%      end

%      if ~normFrames
%        % When frames are not normalised, account the descriptor region
%        magFactor = obj.Opts.magnification^2;
%        framesA = [framesA(1:2,:); framesA(3:5,:).*magFactor];
%        framesB = [framesB(1:2,:); framesB(3:5,:).*magFactor];
%%        reprojFramesB = [reprojFramesB(1:2,:); ...
%%          reprojFramesB(3:5,:).*magFactor];
%      end

%      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
%      numFramesA = size(framesA,2);
%      numFramesB = size(reprojFramesB,2);

%      % Find all ellipse overlaps (in one-to-n array)
%      frameOverlaps = fastEllipseOverlap(reprojFramesB, framesA, ...
%        'NormaliseFrames',normFrames,'MinAreaRatio',overlapThresh,...
%        'NormalisedScale',obj.Opts.normalisedScale);


      frameOverlaps = dataset.getFrameOverlaps(imageAId, imageBId, framesA, framesB);

      numFramesA = size(framesA,2);
      numFramesB = size(framesB,2);

      matches = [];

      if matchGeometry
        % Create an edge between each feature in A and in B
        % weighted by the overlap. Each edge is a candidate match.
        corresp = cell(1,numFramesA);
        for j=1:numFramesA
          numNeighs = length(frameOverlaps.scores{j});
          if numNeighs > 0
            corresp{j} = [j *ones(1,numNeighs); ...
                          frameOverlaps.neighs{j}; ...
                          frameOverlaps.scores{j}];
          end
        end
        corresp = cat(2,corresp{:}) ;
        if isempty(corresp)
          score = 0; numMatches = 0; matches = zeros(1,numFramesA); return;
        end

        % Remove edges (candidate matches) that have insufficient overlap
        corresp = corresp(:,corresp(3,:) > overlapThresh) ;
        if isempty(corresp)
          score = 0; numMatches = 0; matches = zeros(1,numFramesA); return;
        end

        % Sort the edgest by decrasing score
        [drop, perm] = sort(corresp(3,:), 'descend');
        corresp = corresp(:, perm);

        % Approximate the best bipartite matching
        obj.info('Matching frames geometry.');
        geometryMatches = greedyBipartiteMatching(numFramesA,...
          numFramesB, corresp(1:2,:)');

        matches = [matches ; geometryMatches];
      end

      if matchDescriptors
        obj.info('Computing cross distances between all descriptors');
        dists = vl_alldist2(single(descriptorsA),single(descriptorsB),...
          obj.Opts.descriptorsDistanceMetric);
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
      matches = matches(1,:) .* validMatches;

      % Compute the score
      numBestMatches = sum(matches ~= 0);
      score = numBestMatches / min(size(framesA,2), size(framesB,2));
      numMatches = numBestMatches;

      obj.info('Score: %g \t Num matches: %g', ...
        score,numMatches);

      obj.debug('Score between %d/%d frames comp. in %gs',size(framesA,2), ...
        size(framesB,2),toc(startTime));
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end
  end

  methods (Access = protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer(),helpers.VlFeatInstaller('0.9.14'),...
        benchmarks.helpers.Installer()};
    end



  end % methods (Access = protected)

end

