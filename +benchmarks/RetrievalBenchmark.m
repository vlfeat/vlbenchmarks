classdef RetrievalBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
%RETREIVALBENCHMARK
%
% REFERENCES
% [1] H. Jegou, M. Douze and C. Schmid,
%     Exploiting descriptor distances for precise image search,
%     Research report, INRIA 2011
%     http://hal.inria.fr/inria-00602325/PDF/RA-7656.pdf

% AUTORIGHTS

  properties
    opts = struct(...
      'k', 50,...
      'distMetric', 'L2',...
      'maxNumQueries',inf);
  end

  properties (Constant)
    resultsKeyPrefix = 'retreivalResults';
    queryResKeyPrefix = 'retreivalQueryResults';
    datasetFeaturesKeyPrefix = 'datasetFeatures';
  end

  methods
    function obj = RetrievalBenchmark(varargin)
      obj.benchmarkName = 'RetrBenchmark';
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.benchmarkName,varargin);
      if ~obj.isInstalled()
        obj.warn('Not installed.');
        obj.install();
      end
    end

    function [mAP queriesAp ] = evalDetector(obj, detector, dataset)
      import helpers.*;

      obj.info('Evaluating detector %s on dataset %s.',...
        detector.detectorName, dataset.datasetName);
      startTime = tic;

      % Try to load data from cache
      testSignature = obj.getSignature;
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      queriesSignature = dataset.getQueriesSignature();
      resultsKey = strcat(obj.resultsKeyPrefix, testSignature, ...
        detSignature, imagesSignature, queriesSignature);
      results = DataCache.getData(resultsKey);
      if ~isempty(results)
        [mAP, queriesAp] = results{:};
        obj.debug('Results loaded from cache.');
        return;
      end

      % Try to load already computed queries
      numQueries = min([dataset.numQueries obj.opts.maxNumQueries]);
      queriesAp = zeros(numQueries,1);
      cachedQueries = [];
      queryResKeys = cell(1,numQueries);
      cacheResults = detector.useCache && obj.useCache;
      if cacheResults
        for q = 1:numQueries
          querySignature = dataset.getQuerySignature(q);
          queryResKeys{q} = strcat(obj.queryResKeyPrefix, testSignature,...
            detSignature, imagesSignature, querySignature);
          qResults = DataCache.getData(queryResKeys{q});
          if ~isempty(qResults);
            cachedQueries = [cachedQueries q];
            queriesAp(q) = qResults;
            obj.debug('Query AP %d loaded from cache.',q);
          end
        end
      end
      nonComputedQueries = setdiff(1:numQueries,cachedQueries);

      % Retreive features of all images
      [frames descriptors] = obj.getAllDatasetFeatures(dataset, detector);

      % Compute average precisions
      parfor q = nonComputedQueries
        obj.info('Computing query %d/%d.',q,numQueries);
        query = dataset.getQuery(q);
        queriesAp(q) = obj.evalQuery(frames, descriptors, query);
        if cacheResults
          DataCache.storeData(queriesAp(q), queryResKeys{q});
        end
      end

      mAP = mean(queriesAp);
      obj.debug('mAP computed in %fs.',toc(startTime));
      obj.info('Computed mAP is: %f',mAP);

      results = {mAP, queriesAp};
      DataCache.storeData(results, resultsKey);
    end

    function [ap rankedList pr] = evalQuery(obj, frames, descriptors, query)
      import helpers.*;
      import benchmarks.*;

      startTime = tic;
      k = obj.opts.k;

      qImgId = query.imageId;
      % Pick only features in the query box
      qFrames = localFeatures.helpers.frameToEllipse(frames{qImgId});
      visibleFrames = helpers.isEllipseInBBox(query.box, qFrames);
      qDescriptors = single(descriptors{qImgId}(:,visibleFrames));
      qNumDescriptors = size(qDescriptors,2);
      allDescriptors = single([descriptors{:}]);

      if qNumDescriptors == 0
        obj.info('No descriptors detected in the query box.');
        ap = 0; rankedList = []; pr = {[],[],[]};
        return;
      end

      numImages = numel(descriptors);
      numDescriptors = cellfun(@(c) size(c,2),descriptors);
      imageIdxs = arrayfun(@(v,n) repmat(v,1,n),1:numImages, ...
        numDescriptors','UniformOutput',false);
      imageIdxs = [imageIdxs{:}];
      
      obj.info('Computing %d-nearest neighbours of %d descriptors.',...
        k,qNumDescriptors);
      distMetric = YaelInstaller.distMetricParamMap(obj.opts.distMetric);
      [indexes, dists] = yael_nn(single(allDescriptors), ...
        single(qDescriptors), min(k, size(qDescriptors,2)),distMetric);

      nnImgIds = imageIdxs(indexes);

      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( dists(end,:), min(k,qNumDescriptors), 1 ) - dists,...
        nnImgIds );
      votes = votes./sqrt(numDescriptors);
      [temp, rankedList]= sort(votes, 'descend'); 

      ap = RetrievalBenchmark.philbinComputeAp(query, rankedList);
      pr = {[] [] []};

      obj.debug('AP calculated in %fs.',toc(startTime));
      obj.info('Computed average precision is: %f',ap);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end

    function [frames descriptors] = getAllDatasetFeatures(obj, dataset, detector)
      import helpers.*;
      numImages = dataset.numImages;

      % Retreive features of all images
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      featKeyPrefix = obj.datasetFeaturesKeyPrefix;
      featuresKey = strcat(featKeyPrefix, detSignature,imagesSignature);
      features = [];
      if detector.useCache
        features = DataCache.getData(featuresKey);
      end;
      if isempty(features)
        % Compute the features
        frames = cell(numImages,1);
        descriptors = cell(numImages,1);
        featStartTime = tic;
        parfor imgNo = 1:numImages
          obj.info('Computing features of image %d/%d.',imgNo,numImages);
          imagePath = dataset.getImagePath(imgNo);
          [frames{imgNo} descriptors{imgNo}] = ...
            detector.extractFeatures(imagePath);
        end
        obj.debug('Features computed in %fs.',toc(featStartTime));
        if detector.useCache
          DataCache.storeData({frames, descriptors},featuresKey);
        end
      else 
        [frames descriptors] = features{:};
        obj.debug('Features loaded from cache.');
      end
    end
  end

  methods(Static)
    function [precision recall info] = calcPR(query, scores)
      y = - ones(1, numel(scores)) ;
      y(query.good) = 1 ;
      y(query.ok) = 1 ;
      y(query.junk) = 0 ;
      y(query.imageId) = 0 ;
      [precision recall info] = vl_pr(y, scores);
    end
    
    function ap = philbinComputeAp(query, rankedList)
      oldRecall = 0.0;
      oldPrecision = 1.0;
      ap = 0.0;
      ambiguous = query.junk;
      positive = [query.good query.ok];
      intersectSize = 0;
      j = 0;
      for i = 1:numel(rankedList)
        if ismember(rankedList(i),ambiguous)
          continue; 
        end
        if ismember(rankedList(i),positive)
          intersectSize = intersectSize + 1;
        end
        recall = intersectSize / numel(positive);
        precision = intersectSize / (j + 1.0);
        ap = ap + (recall - oldRecall)*((oldPrecision + precision)/2.0);
        oldRecall = recall;
        oldPrecision = precision;
        j = j + 1;
      end
    end

    function deps = getDependencies()
      import helpers.*;
      deps = {Installer(),benchmarks.helpers.Installer(),...
        VlFeatInstaller('0.9.14'),YaelInstaller()};
    end
  end  
end

