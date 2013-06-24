classdef DescMatchingBenchmark < benchmarks.GenericBenchmark ...
    & helpers.Logger & helpers.GenericInstaller
  % benchmarks.DescMatchingBenchmark Descriptors matching PR curves
  %   benchmarks.DescMatchingBenchmark('OptionName',optionValue,...)
  %   constructs an object of a becnhmark for testing performance of image
  %   feature descriptors measuring the precision/recall curves as defined in
  %   [1].
  %
  % Options:
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
      'descriptorsDistanceMetric', 'L2',...
      'matchingStrategy','nn',...
      'prPointsNum',inf);
    ConsistencyModel;
  end
  
  properties(Constant, Hidden)
    KeyPrefix = 'descMatching';
    MatchingStrategies = {'threshold','nn','nn-dist-ratio'};
  end
  
  methods
    function obj = DescMatchingBenchmark(consistencyModel, varargin)
      import benchmarks.*;
      import helpers.*;
      obj.BenchmarkName = 'Desc. Matching';
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      varargin = obj.checkInstall(varargin);
      obj.Opts = vl_argparse(obj.Opts,varargin);
      obj.ConsistencyModel = consistencyModel;
    end
    
    function [precision recall subsres] = ...
        testFeatureExtractor(obj, featExtractor, sceneGeometry, imageAPath, ...
        imageBPath)
      % testFeatureExtractor
      %   [PRECISION, RECALL] = obj.testFeatureExtractor(FEAT_EXTR, TF, ...
      %   IMG_A_PATH, IMG_B_PATH)
      %
      %   [PRECISION, RECALL, INFO] =
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

      resultsKey = cell2str({obj.KeyPrefix, obj.getSignature(), ...
        featExtractor.getSignature(), imageASign, imageBSign});
      cachedResults = obj.loadResults(resultsKey);
      
      % When detector does not cache results, do not use the cached data
      if isempty(cachedResults) || ~featExtractor.UseCache
        [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
        [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
        [precision recall subsres] = obj.testFeatures(sceneGeometry, ...
          framesA, framesB, descriptorsA, descriptorsB);
        if featExtractor.UseCache
          results = {precision recall subsres};
          obj.storeResults(results, resultsKey);
        end
      else
        [precision recall subsres] = cachedResults{:};
        obj.debug('Results loaded from cache');
      end
      
    end
    
    function [precision recall subsres] = ...
        testFeatures(obj, sceneGeometry, framesA, framesB, ...
        descriptorsA, descriptorsB)
      % testFeatures
      %   [PRECISION, RECALL] = obj.testFeatures(TF, IMAGE_A_SIZE,
      %   IMAGE_B_SIZE, FRAMES_A, FRAMES_B, DESCS_A, DESCS_B)
      %
      %   [PRECISION, RECALL, INFO] =
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
        subsres = struct(); precision = []; recall = [];
        obj.info('Nothing to compute.');
        return;
      end
      if size(framesA,2) ~= size(descriptorsA,2) ...
          || size(framesB,2) ~= size(descriptorsB,2)
        obj.error('Number of frames and descriptors must be the same.');
      end
      
      startTime = tic;
      [correspondences consistency subsres] = ...
        obj.ConsistencyModel.findConsistentCorresps(sceneGeometry, framesA, framesB);
      
      if isempty(correspondences), return; end;
      
      if isfield(subsres,'validFramesA') && isfield(subsres,'validFramesB')
        descriptorsA = descriptorsA(:,subsres.validFramesA);
        descriptorsB = descriptorsB(:,subsres.validFramesB);
      end
      
      numFramesA = size(descriptorsA,2);
      numFramesB = size(descriptorsB,2);
      
      % Create indexes of positive values in incidence matrix
      validCorrespIdxs = sub2ind([numFramesA, numFramesB], ...
        correspondences(1,:), correspondences(2,:));
      
      switch obj.Opts.matchingStrategy
        case 'threshold'
          % Count number of correspondences for each frame
          numCorresps = size(consistency,2);
        case {'nn','nn-dist-ratio'}
          % Sort the edges by decrasing score
          [drop, perm] = sort(consistency, 'descend');
          sortedCorrespondences = correspondences(:, perm);
          
          % Find one to one stable matching
          obj.info('Matching frames geometry.');
          geometryMatches = greedyBipartiteMatching(numFramesA,...
            numFramesB, sortedCorrespondences(1:2,:)');
          subsres.geometryMatches = geometryMatches;
          
          numCorresps = sum(geometryMatches > 0);
      end
      obj.info('Number of correspondences: %d',numCorresps);
      
      score = [];
      matches = [];
      labels = [];
      switch obj.Opts.matchingStrategy
        case 'threshold'
          matcher = benchmarks.helpers.DataMatcher('matchStrategy','all');
          [matches dists] = matcher.matchData(descriptorsA, descriptorsB);
          [dists, perm] = sort(dists(:),'ascend');
          
          labels = -ones(numFramesA, numFramesB);
          labels(validCorrespIdxs) = 1;
          labels = labels(perm);
          
          score = -dists(:);
          labels = labels(:);
        case {'nn','nn-dist-ratio'}
          switch obj.Opts.matchingStrategy
            case 'nn'
              matcher = benchmarks.helpers.DataMatcher('matchStrategy','1to1');
            case 'nn-dist-ratio'
              matcher = benchmarks.helpers.DataMatcher('matchStrategy','1to1secondclosest');
          end
          
          [matches dists] = matcher.matchData(descriptorsB, descriptorsA);
          score = -inf(1,numFramesA);
          labels = -ones(1,numFramesA);
          % In case of nn, dists contains descriptor distance -> use
          % inverse. In case of second closes it contains ratio of the
          % closest to the second closest - use inverse as well.
          % In original KM code the second closest ratio is a ratio of the
          % second closest to the closest descriptor (inverse).
          score(matches(2,:)) = -dists;
          
          % Idxs of matches in incidence matrix
          matchesIdxs = sub2ind([numFramesA, numFramesB], ...
            matches(2,:), matches(1,:));
          
          % Find matches with enough overlap
          [drop validMatch] = intersect(matchesIdxs, validCorrespIdxs);
          
          labels(matches(2,validMatch)) = 1;
      end
      numCorrectMatches = sum(labels > 0);
      obj.info('Number of correct matches: %d',numCorrectMatches);
      
      [recall precision info] = vl_pr(labels,score,'NumPositives',numCorresps);
      subsres = vl_override(subsres, info);
      subsres.numCorresp = numCorresps;
      subsres.numCorrectMatches = numCorrectMatches;
      subsres.descMatches = matches;
      subsres.descDists = dists;
      
      if ~isinf(obj.Opts.prPointsNum)
        numValues = numel(recall);
        switch obj.Opts.matchingStrategy
          case 'threshold'
            samples = round(logspace(0,log10(numValues),obj.Opts.prPointsNum));
          case {'nn','nn-dist-ratio'}
            samples = round(linspace(1,numValues,obj.Opts.prPointsNum));
        end
        subsres.recall_all = recall;
        subsres.precision_all = precision;
        recall = recall(samples);
        precision = precision(samples);
      end
      
      if nargout > 2
        subsres.matches = matches;
        subsres.labels = labels;
        subsres.distances = dists;
      end
      
      obj.debug('Results between %d/%d frames comp. in %gs',numFramesA, ...
        numFramesB,toc(startTime));
    end

    function signature = getSignature(obj)
      signature = [helpers.struct2str(obj.Opts) ...
        obj.ConsistencyModel.getSignature()];
    end
  end
  
  methods (Access = protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer(),helpers.VlFeatInstaller('0.9.14'), ...
        benchmarks.helpers.DataMatcher()};
    end
  end
  
end

