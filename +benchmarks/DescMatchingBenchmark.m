classdef DescMatchingBenchmark < benchmarks.GenericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
% benchmarks.DescMatchingBenchmark Descriptors matching PR curves
%   benchmarks.DescMatchingBenchmark('OptionName',optionValue,...) 
%   constructs an object of a becnhmark for testing performance of image
%   feature descriptors measuring the precision/recall curves as defined in
%   [1].
%
%   OverlapError:: 0.5
%     Maximal overlap error of two frames to be considered as a valid
%     correspondence.
%
%   CropFrames:: true
%     Crop the frames out of overlapping regions (regions present in both
%     images).
%
%   WarpMethod:: 'linearise'
%     Numerical method used for warping ellipses. Available mathods are
%     'standard' and 'linearise' for precise reproduction of IJCV2005 
%     benchmark results.
%
%   DescriptorsDistanceMetric:: 'L2'
%     Distance metric used for matching the descriptors. See
%     documentation of vl_alldist2 for details.
%
%   See also: datasets.VggAffineDataset, vl_alldist2
%
%   REFERENCES
%   [1] K. Mikolajczyk, C. Schmid. A performace Evaluation of Local
%       Descriptors. IEEE PAM, 2005.

% Authors: Karel Lenc

% AUTORIGHTS

  properties
    Opts = struct(...
      'overlapError', 0.5,...
      'cropFrames', false,...
      'warpMethod', 'linearise',...
      'descriptorsDistanceMetric', 'L2',...
      'matchingStrategy','nn');
  end

  properties(Constant, Hidden)
    KeyPrefix = 'descMatching';
    MatchingStrategies = {'threshold','nn','nn-dist-ratio'};
  end

  methods
    function obj = DescMatchingBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      obj.BenchmarkName = 'Desc. Matching';
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end

    function [precision recall info bestMatches reprojFrames] = ...
        testFeatureExtractor(obj, featExtractor, tf, imageAPath, ...
        imageBPath, magnification)
      % testFeatureExtractor
      %   [PRECISION, RECALL] = obj.testFeatureExtractor(FEAT_EXTR, TF, ...
      %   IMG_A_PATH, IMG_B_PATH, MAGNIF) 
      %
      %   [PRECISION, RECALL, REPR_FRAMES, MATCHES] =
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
      %   See also: benchmarks.DescMatchingBenchmark().
      import benchmarks.*;
      import helpers.*;

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
      if isempty(cachedResults) || ~featExtractor.UseCache
        [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
        [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
        [precision recall info bestMatches reprojFrames] = obj.testFeatures(...
          tf, imageASize, imageBSize, framesA, framesB,...
          descriptorsA, descriptorsB, magnification);
        if featExtractor.UseCache
          results = {precision recall info bestMatches reprojFrames};
          obj.storeResults(results, resultsKey);
        end
      else
        [precision recall info bestMatches reprojFrames] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end

    end

    function [precision recall info matches reprojFrames] = ...
        testFeatures(obj, tf, imageASize, imageBSize, framesA, framesB, ...
        descriptorsA, descriptorsB, magnification)
      % testFeatures Compute repeatability of given image features
      %   [PRECISION, RECALL] = obj.testFeatures(TF, IMAGE_A_SIZE,
      %   IMAGE_B_SIZE, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B, MAGNIF)
      %
      %   [PRECISION, RECALL, REPR_FRAMES, MATCHES] =
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

      obj.info('Computing matches between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      if isempty(framesA) || isempty(framesB)
        matches = zeros(size(framesA,2)); reprojFrames = {}; 
        obj.info('Nothing to compute.');
        return;
      end
      if size(framesA,2) ~= size(descriptorsA,2) ...
          || size(framesB,2) ~= size(descriptorsB,2)
        obj.error('Number of frames and descriptors must be the same.');
      end

      startTime = tic;
      overlapError = obj.Opts.overlapError;
      overlapThresh = 1 - overlapError;

      % convert frames from any supported format to unortiented
      % ellipses for uniformity
      framesA = localFeatures.helpers.frameToEllipse(framesA) ;
      framesB = localFeatures.helpers.frameToEllipse(framesB) ;

      % map frames from image A to image B and viceversa
      reprojFramesA = warpEllipse(tf, framesA,...
        'Method',obj.Opts.warpMethod) ;
      reprojFramesB = warpEllipse(inv(tf), framesB,...
        'Method',obj.Opts.warpMethod) ;

      % optionally remove frames that are not fully contained in
      % both images
      if obj.Opts.cropFrames
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
        if isempty(framesA) || isempty(framesB)
          matches = zeros(size(framesA,2)); reprojFrames = {};
          return;
        end
        descriptorsA = descriptorsA(:,visibleFramesA);
        descriptorsB = descriptorsB(:,visibleFramesB);
      end

      % When frames are not normalised, account the descriptor region
      magFactor = magnification^2;
      framesA = [framesA(1:2,:); framesA(3:5,:).*magFactor];
      reprojFramesB = [reprojFramesB(1:2,:); ...
        reprojFramesB(3:5,:).*magFactor];

      reprojFrames = {framesA,framesB,reprojFramesA,reprojFramesB};
      numFramesA = size(framesA,2);
      numFramesB = size(reprojFramesB,2);

      obj.info('Computing frame overlaps');
      frameOverlaps = fastEllipseOverlap(reprojFramesB, framesA, ...
        'NormaliseFrames',false,'MinAreaRatio',overlapThresh);
      numCorresps = sum(cellfun(@(a) sum(a > overlapThresh),frameOverlaps.scores));
      obj.info('Number of correspondences: %d',numCorresps);
      descriptorsA = single(descriptorsA);
      descriptorsB = single(descriptorsB);
      
      score = [];
      matches = [];
      labels = [];
      switch obj.Opts.matchingStrategy
        case 'threshold'
          obj.info('Computing cross distances between all descriptors');
          dists = vl_alldist2(descriptorsA,descriptorsB,...
          obj.Opts.descriptorsDistanceMetric);
          labels = -ones(numFramesA, numFramesB);
          for aIdx=1:numFramesA
            neighs = frameOverlaps.neighs{aIdx};
            overlaps = frameOverlaps.scores{aIdx};
            hasEnoughOverlap = overlaps >= overlapThresh;
            labels(aIdx,neighs(hasEnoughOverlap)) = 1;
          end
          [aIdx bIdx] = ind2sub([numFramesA, numFramesB],1:numel(dists));
          matches = [aIdx bIdx];
          score = -dists(:);
          labels = labels(:);
        case {'nn','nn-dist-ratio'}
          obj.info('Building kd-tree.');
          kdtree = vl_kdtreebuild(descriptorsB) ;
          %[dists, perm] = sort(dists,2,'ascend');
          %matches = [1:numFramesA;perm(:,1)'];
          obj.info('Querying kd-tree.');
          switch obj.Opts.matchingStrategy
            case 'nn'
              [index, dists] = vl_kdtreequery(kdtree, descriptorsB,...
                descriptorsA, 'NumNeighbors', 1) ;
              score = -dists(1,:);
            case 'nn-dist-ratio'
              [index, dists] = vl_kdtreequery(kdtree, descriptorsB,...
                descriptorsA, 'NumNeighbors', 2) ;
              score = -dists(1,:)./dists(2,:);
          end
          labels = -ones(1,numFramesA);
          for aIdx=1:numFramesA
            bIdx = index(1,aIdx);
            [hasCorresp bCorresp] = ismember(bIdx,frameOverlaps.neighs{aIdx});
            % Check whether found descriptor matches fulfill frame overlap
            if hasCorresp && ...
               frameOverlaps.scores{aIdx}(bCorresp) >= overlapThresh
              labels(aIdx) = 1;
            end
          end
      end
      numCorrectMatches = sum(labels > 0);
      obj.info('Number of correct matches: %d',numCorrectMatches);
      [recall precision info] = vl_pr(labels,score,'NumPositives',numCorresps);
      %[recall precision] = vl_pr(labels,score);

      obj.debug('Results between %d/%d frames comp. in %gs',size(framesA,2), ...
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
  end

end

