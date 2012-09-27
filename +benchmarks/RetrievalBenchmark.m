classdef RetrievalBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
%RETREIVALBENCHMARK
%
% REFERENCES
% [1] H. Jegou, M. Douze and C. Schmid,
%     Exploiting descriptor distances for precise image search,
%     Research report, INRIA 2011
%     http://hal.inria.fr/inria-00602325/PDF/RA-7656.pdf

% Authors: Karel Lenc, Relja Arandjelovic

% AUTORIGHTS

  properties
    Opts = struct(...
      'k', 50,...
      'distMetric', 'L2',...
      'maxNumImagesPerSearch',1000);
  end

  properties (Constant, Hidden)
    ResultsKeyPrefix = 'retreivalResults~';
    QueryKnnsKeyPrefix = 'retreivalQueryKnns~';
    DatasetFeaturesKeyPrefix = 'datasetAllFeatures~';
    DatasetChunkInfoPrefix = 'datasetChunkInfo~';
  end

  methods
    function obj = RetrievalBenchmark(varargin)
      obj.BenchmarkName = 'RetrBenchmark';
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end

    function [mAP, queriesAp, rankedLists, votes, numDescriptors] = ...
        evalDetector(obj, detector, dataset)
      import helpers.*;
      obj.info('Evaluating detector %s on dataset %s.',...
        detector.Name, dataset.DatasetName);
      startTime = tic;

      % Try to load results from cache
      numImages = dataset.NumImages;
      testSignature = obj.getSignature;
      detSignature = detector.getSignature;
      obj.info('Computing signatures of %d images.',numImages);
      imagesSignature = dataset.getImagesSignature();
      queriesSignature = dataset.getQueriesSignature();
      resultsKey = strcat(obj.ResultsKeyPrefix, testSignature, ...
        detSignature, imagesSignature, queriesSignature);
      if obj.UseCache
        results = DataCache.getData(resultsKey);
        if ~isempty(results)
          [mAP, queriesAp] = results{:};
          obj.debug('Results loaded from cache.');
          return;
        end
      end
      % Divide the dataset into chunks
      imgsPerChunk = obj.Opts.maxNumImagesPerSearch;
      numChunks = ceil(numImages/imgsPerChunk);
      knns = cell(numChunks,1); % as image indexes
      knnDists = cell(numChunks,1);
      numDescriptors = cell(1,numChunks);
      obj.info('Dataset has to been divided into %d chunks.',numChunks);

      % Load query descriptors
      qDescriptors = obj.gatherQueriesDescriptors(dataset, detector);

      % Compute KNNs for all image chunks
      for chNum = 1:numChunks
        firstImageNo = (chNum-1)*imgsPerChunk+1;
        lastImageNo = min(chNum*imgsPerChunk,numImages);
        [knns{chNum}, knnDists{chNum}, numDescriptors{chNum}] = ...
          obj.computeKnns(dataset,detector,qDescriptors,...
          firstImageNo,lastImageNo);
      end
      % Compute the AP
      numDescriptors = cell2mat(numDescriptors);
      numQueries = dataset.NumQueries;
      obj.info('Computing the average precisions.');
      queriesAp = zeros(1,numQueries);
      rankedLists = zeros(numImages,numQueries);
      votes = zeros(numImages,numQueries);
      for q=1:numQueries
        % Combine knns of all descriptors from all chunks
        allQKnns = cell(numChunks,1);
        allQKnnDists = cell(numChunks,1);
        for ch = 1:numChunks
          allQKnns{ch} = knns{ch}{q};
          allQKnnDists{ch} = knnDists{ch}{q};
        end
        allQKnns = cell2mat(allQKnns(~cellfun('isempty',allQKnns)));
        allQKnnDists = cell2mat(allQKnnDists(~cellfun('isempty',allQKnnDists)));

        % Sort them by the distance to the query descriptors
        [allQKnnDists ind] = sort(allQKnnDists,1,'ascend');
        for qd = 1:size(allQKnnDists,2)
           allQKnns(:,qd) = allQKnns(ind(:,qd),qd);
        end
        % Pick the upper k
        fk = min(obj.Opts.k,size(allQKnns,2));
        allQKnns = allQKnns(1:fk,:);
        allQKnnDists = allQKnnDists(1:fk,:);

        query = dataset.getQuery(q);
        [queriesAp(q) rankedLists(:,q) votes(:,q)] = ...
          obj.computeAp(allQKnns, allQKnnDists, numDescriptors, query);
        obj.info('Average precision of query %d: %f',q,queriesAp(q));
      end
      
      mAP = mean(queriesAp);
      obj.debug('mAP computed in %fs.',toc(startTime));
      obj.info('Computed mAP is: %f',mAP);

      results = {mAP, queriesAp, rankedLists, votes, numDescriptors};
      if obj.UseCache
        DataCache.storeData(results, resultsKey);
      end
    end

    function qDescriptors = gatherQueriesDescriptors(obj, dataset, detector)
      import benchmarks.*;
      % Gather query descriptors
      obj.info('Computing query descriptors.');
      numQueries = dataset.NumQueries;
      qDescriptors = cell(1,numQueries);
      for q=1:numQueries
        query = dataset.getQuery(q);
        imgPath = dataset.getImagePath(query.imageId);
        [qFrames qDescriptors{q}] = detector.extractFeatures(imgPath);
        % Pick only features in the query box
        qFrames = localFeatures.helpers.frameToEllipse(qFrames);
        visibleFrames = helpers.isEllipseInBBox(query.box, qFrames);
        qDescriptors{q} = qDescriptors{q}(:,visibleFrames);
      end
    end

    function [ap rankedList votes] = computeAp(obj, knnImgIds, knnDists,...
        numDescriptors, query)
      import helpers.*;

      k = obj.Opts.k;
      numImages = numel(numDescriptors);
      qNumDescriptors = size(knnImgIds,2);

      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( knnDists(end,:), min(k,qNumDescriptors), 1 ) - knnDists,...
        knnImgIds );
      votes = votes./sqrt(max(numDescriptors',1));
      [votes, rankedList]= sort(votes, 'descend'); 

      ap = obj.philbinComputeAp(query, rankedList);
    end

    function [queriesKnns, queriesKnnDists numDescriptors] = ...
        computeKnns(obj, dataset, detector, qDescriptors, firstImageNo,...
        lastImageNo)
      import helpers.*;
      startTime = tic;
      numQueries = dataset.NumQueries;
      k = obj.Opts.k;
      numImages = lastImageNo - firstImageNo + 1;
      queriesKnns = cell(1,numQueries);
      queriesKnnDists = cell(1,numQueries);

      testSignature = obj.getSignature;
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature(firstImageNo:lastImageNo);

      % Try to load already computed queries
      isCachedQuery = false(1,numQueries);
      nonCachedQueries = 1:numQueries;
      knnsResKeys = cell(1,numQueries);
      imgsInfoKey = strcat(obj.DatasetChunkInfoPrefix, testSignature,...
          detSignature, imagesSignature);
      cacheResults = detector.UseCache && obj.UseCache;
      if cacheResults
        for q = 1:numQueries
          querySignature = dataset.getQuerySignature(q);
          knnsResKeys{q} = strcat(obj.QueryKnnsKeyPrefix, testSignature,...
            detSignature, imagesSignature, querySignature);
          qKnnResults = DataCache.getData(knnsResKeys{q});
          if ~isempty(qKnnResults);
            isCachedQuery(q) = true;
            [queriesKnns{q} queriesKnnDists{q}] = qKnnResults{:};
            obj.debug('Query KNNs %d for images %d:%d loaded from cache.',...
              q,firstImageNo, lastImageNo);
          end
        end
        nonCachedQueries = find(~isCachedQuery);
        % Try to avoid loading the features when all queries already 
        % computed, what need to be loaded only is the number of 
        % descriptors per image.
        numDescriptors = DataCache.getData(imgsInfoKey);
        if isempty(nonCachedQueries) && ~isempty(numDescriptors)
          return; 
        end;
      end

      % Retreive features of the images
      [descriptors imageIdxs numDescriptors] = ...
        obj.getDatasetFeatures(dataset,detector,firstImageNo, lastImageNo);

      if cacheResults
        DataCache.storeData(imgsInfoKey,numDescriptors);
      end

      % Compute the KNNs
      helpers.DataCache.disableAutoClear();
      parfor q = nonCachedQueries
        obj.info('Imgs %d:%d - Computing KNNs for query %d/%d.',...
          firstImageNo,lastImageNo,q,numQueries);
        [knnDescIds, queriesKnnDists{q}] = ...
          obj.computeKnn(descriptors, qDescriptors{q});
        queriesKnns{q} = imageIdxs(knnDescIds);
        if cacheResults
          DataCache.storeData({queriesKnns{q}, queriesKnnDists{q}},...
            knnsResKeys{q});
        end
      end
      helpers.DataCache.enableAutoClear();
      obj.debug('All %d-NN for %d images computed in %gs.',...
        k, numImages, toc(startTime));
    end

    function [knnDescIds, knnDists] = computeKnn(obj, descriptors, qDescriptors)
      import helpers.*;
      import benchmarks.*;

      startTime = tic;
      k = obj.Opts.k;

      qNumDescriptors = size(qDescriptors,2);

      if qNumDescriptors == 0
        obj.info('No descriptors detected in the query box.');
        return;
      end

      obj.info('Computing %d-NN of %d descs in db of %d descs.',...
        k,qNumDescriptors,size(descriptors,2));
      distMetric = YaelInstaller.DistMetricParamMap(obj.Opts.distMetric);
      [knnDescIds, knnDists] = yael_nn(single(descriptors), ...
        single(qDescriptors), min(k, size(qDescriptors,2)),distMetric);

      obj.debug('KNN calculated in %fs.',toc(startTime));
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end

    function [descriptors imageIdxs numDescriptors] = ...
        getDatasetFeatures(obj, dataset,detector, firstImageNo, lastImageNo)
      import helpers.*;
      numImages = lastImageNo - firstImageNo + 1;

      % Retreive features of all images
      detSignature = detector.getSignature;
      obj.info('Computing signatures of %d images.',numImages);
      imagesSignature = dataset.getImagesSignature(firstImageNo:lastImageNo);
      featKeyPrefix = obj.DatasetFeaturesKeyPrefix;
      featuresKey = strcat(featKeyPrefix,detSignature,imagesSignature);
      features = [];
      if detector.UseCache && DataCache.hasData(featuresKey)
        obj.info('Loading descriptors of %d images from cache.',numImages);
        features = DataCache.getData(featuresKey);
      end;
      if isempty(features)
        % Compute the features
        descriptorsStore = cell(1,numImages);
        featStartTime = tic;
        helpers.DataCache.disableAutoClear();
        parfor id = 1:numImages
          imgNo = firstImageNo + id - 1;
          obj.info('Computing features of image %d (%d/%d).',...
            imgNo,id,numImages);
          imagePath = dataset.getImagePath(imgNo);
          % Frames are ommited as score is computed from descs. only
          [frames descriptorsStore{id}] = ...
            detector.extractFeatures(imagePath);
        end
        helpers.DataCache.enableAutoClear();
        obj.debug('Features computed in %fs.',toc(featStartTime));
        % Put descriptors in a single array
        descriptors = single(cell2mat(descriptorsStore));
        numDescriptors = cellfun(@(c) size(c,2),descriptorsStore);
        imageIdxs = arrayfun(@(v,n) repmat(v,1,n),firstImageNo:lastImageNo, ...
          numDescriptors,'UniformOutput',false);
        imageIdxs = [imageIdxs{:}];
        
        if detector.UseCache
          features = {descriptors, imageIdxs, numDescriptors};
          obj.debug('Saving %d descriptors to cache.',size(descriptors,2));
          DataCache.storeData(features,featuresKey);
        end
      else 
        [descriptors imageIdxs numDescriptors] = features{:};
        obj.debug('%d features loaded from cache.',size(descriptors,2));
      end
    end
  end

  methods (Access = protected)
    function deps = getDependencies(obj)
      import helpers.*;
      deps = {Installer(),benchmarks.helpers.Installer(),...
        VlFeatInstaller('0.9.14'),YaelInstaller()};
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
  end  
end

