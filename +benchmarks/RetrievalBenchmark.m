classdef RetrievalBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
% benchmarks.RetrievalBenchmark KNN Retrieval benchmark
%   benchmarks.RetrievalBenchmark('OptionName',optionValue,...)
%   constructs an object to compute the feature extractor performance in a 
%   simple image retrieval system setting [1] based on K-Nearest Neighbours
%   (KNN).
%
%   Object constructor accepts the following options:
%
%   K :: 50
%     Number of descriptor nearest neighbours used for the retrieval.
%
%   DistMetric ::
%     Distance metric used by the KNN algorithm.
%
%   MaxNumImagesPerSearch :: 1000
%     Maimal number of images which descriptors are in the database. If the
%     number of images in dataset is bigger, it is divided into several
%     chunks.
%     Decrease this number if your computer is runing out of memory.
%
%
% REFERENCES
%   [1] H. Jegou, M. Douze and C. Schmid,
%       Exploiting descriptor distances for precise image search,
%       Research report, INRIA 2011
%       http://hal.inria.fr/inria-00602325/PDF/RA-7656.pdf
%
%   [2] J. Philbin, O. Chum, M. Isard, J. Sivic and A. Zisserman.
%       Object retrieval with large vocabularies and fast spatial 
%       matching CVPR, 2007

% Authors: Karel Lenc, Relja Arandjelovic

% AUTORIGHTS
  properties
    % Object options
    Opts = struct(...
      'k', 50,...
      'distMetric', 'L2',...
      'maxNumImagesPerSearch',1000);
  end

  properties (Constant, Hidden)
    % Key prefix for final results
    ResultsKeyPrefix = 'retreivalResults';
    % Key prefix for KNN computation results (most time consuming)
    QueryKnnsKeyPrefix = 'retreivalQueryKnns';
    % Key prefix for bunch of all detector features.
    DatasetFeaturesKeyPrefix = 'datasetAllFeatures';
    % Key prefix for additional information about the detector features
    DatasetChunkInfoPrefix = 'datasetChunkInfo';
  end

  methods
    function obj = RetrievalBenchmark(varargin)
      obj.BenchmarkName = 'RetrBenchmark';
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end

    function [mAP, queriesAp, rankedLists, votes, numDescriptors] = ...
        testFeatureExtractor(obj, featExtractor, dataset)
      % testFeatureExtractor Test image feature extractor in a retrieval test
      %   MAP = obj.testFeatureExtractor(FEAT_EXTRACTOR, DATASET) Compute 
      %   mean average precision of a detector in the retrieval test.
      %   FEAT_EXTRACTOR must be a subclass of
      %   localFeatures.GenericLocalFeatureExtractor and must be able to
      %   compute both feature frames and their descriptors. DATASET must
      %   be an object of datasets.VggRetrievalDataset class.
      %
      %   [MAP QUERIES_AP RANKED_LIST VOTES NUM_DESCS] = ...
      %   obj.testDetector(DETECTOR, DATASET) Returns also QUERIES_AP,
      %   average precision of a detector per a single query, RANKED_LIST,
      %   array of size [DATASET.NumImages, DATASET.NumQueries] where each
      %   RANKED_LIST(:,QUERY_NUM) contain IDs of images from the dataset
      %   ranked by the voting score which is stored in VOTES(:,QUERY_NUM).
      %   Size of array VOTES is the same as of RANKED_LIST.
      %   NUM_DESCS is an array of size [1 DATASET.NumImages] storing the
      %   number of descriptors detected in a particular dataset image.
      import helpers.*;
      obj.info('Evaluating detector %s on dataset %s.',...
        featExtractor.Name, dataset.DatasetName);
      startTime = tic;

      % Try to load results from cache
      numImages = dataset.NumImages;
      testSignature = obj.getSignature;
      detSignature = featExtractor.getSignature;
      obj.info('Computing signatures of %d images.',numImages);
      imagesSignature = dataset.getImagesSignature();
      queriesSignature = dataset.getQueriesSignature();
      resultsKey = strcat(obj.ResultsKeyPrefix, testSignature, ...
        detSignature, imagesSignature, queriesSignature);
      if obj.UseCache
        results = DataCache.getData(resultsKey);
        if ~isempty(results)
          [mAP, queriesAp, rankedLists, votes, numDescriptors]=results{:};
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
      qDescriptors = obj.gatherQueriesDescriptors(dataset, featExtractor);

      % Compute KNNs for all image chunks
      for chNum = 1:numChunks
        firstImageNo = (chNum-1)*imgsPerChunk+1;
        lastImageNo = min(chNum*imgsPerChunk,numImages);
        [knns{chNum}, knnDists{chNum}, numDescriptors{chNum}] = ...
          obj.computeKnns(dataset,featExtractor,qDescriptors,...
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
  
    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end
  end
    
  methods (Access=protected, Hidden)
    function qDescriptors = gatherQueriesDescriptors(obj, dataset, ...
        featExtractor)
      % gatherQueriesDescriptors Compute queries descriptors
      %   Q_DESCRIPTORS = obj.gatherQueriesDescriptors(DATASET,FEAT_EXTRACT)
      %   computes Q_DESCRIPTORS, cell array of size 
      %   [1, DATASET.NumQueries] where each cell contain descriptors from
      %   the query bounding box computed in the query image using feature
      %   extractor FEAT_EXTRACTOR.
      import benchmarks.*;
      % Gather query descriptors
      obj.info('Computing query descriptors.');
      numQueries = dataset.NumQueries;
      qDescriptors = cell(1,numQueries);
      for q=1:numQueries
        query = dataset.getQuery(q);
        imgPath = dataset.getImagePath(query.imageId);
        [qFrames qDescriptors{q}] = featExtractor.extractFeatures(imgPath);
        % Pick only features in the query box
        qFrames = localFeatures.helpers.frameToEllipse(qFrames);
        visibleFrames = helpers.isEllipseInBBox(query.box, qFrames);
        qDescriptors{q} = qDescriptors{q}(:,visibleFrames);
      end
    end

    function [ap rankedList votes] = computeAp(obj, knnImgIds, knnDists,...
        numDescriptors, query)
      % computeAp Compute average precision from KNN results
      %   [AP RANKED_LIST VOTES] = obj.computeAp(KNN_IMG_IDS, KNN_DISTS,
      %      NUM_DESCRIPTORS, QUERY) Compute average precision of the
      %   results of K-nearest neighbours search. Result of this search is
      %   set of K descriptors for each query descriptors.
      %   Array KNN_IMG_IDS has size [K,QUERY_DESCRIPTORS_NUM] and value
      %   KNN_IMG_IDS(N,I) is the ID of the image in which the
      %   N-nearest neighbour desc. of the Ith query descriptor was found.
      %   Array KNN_DISTS has size [K,QUERY_DESCRIPTORS_NUM] and value
      %   KNN_DISTS(N,I) is the distance of the N-Nearest descriptor to the
      %   Ith query descriptor.
      %   Array NUM_DESCRIPTORS of size [1, NUM_IMAGES_IN_DB] contains the
      %   number of descriptors extracted from the database images.
      import helpers.*;

      k = obj.Opts.k;
      numImages = numel(numDescriptors);
      qNumDescriptors = size(knnImgIds,2);

      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( knnDists(end,:), min(k,qNumDescriptors), 1 ) - knnDists,...
        knnImgIds );
      votes = votes./sqrt(max(numDescriptors',1));
      [votes, rankedList]= sort(votes, 'descend'); 

      ap = obj.rankedListAp(query, rankedList);
    end

    function [queriesKnns, queriesKnnDists numDescriptors] = ...
        computeKnns(obj, dataset, featExtractor, qDescriptors, firstImageNo,...
        lastImageNo)
      % computeKnns Compute the K-nearest neighbours of query descriptors
      %   [QUERIES_KNNS KNNS_DISTS, NUM_DESCRIPTORS] = computeKnns(DATASET,
      %     FEAT_EXTRACTOR, QUERIES_DESCRIPTORS, FIRST_IMG_NO, LAST_IMG_NO)
      %   computes KNN of all query descriptors in the database from all
      %   descriptors extracted from images [FIRST_IMG_NO, LAST_IMG_NO].
      %
      %   QUERIES_DESCRIPTORS is a cell array of size [1, DATASET.NumQueries]
      %   Array QUERIES_DESCRIPTORS{QID} contain all the descriptors 
      %   QID_DESCRIPTORS extracted by FEAT_EXTRACTOR in the query QID 
      %   bounding box. This array size is [DESC_SIZE,QID_DESCRIPTORS_NUM].
      %
      %   QUERIES_KNNS and KNNS_DISTS are cell arrays of size 
      %   [1, DATASET.NumQueries].
      %   Array QUERIES_KNNS{QID} has size [K,QID_DESCRIPTORS_NUM] and value
      %   QUERIES_KNNS{QID}(N,I) is the ID of the image in which the
      %   N-nearest neighbour desc. of the Ith query QID descriptor was found.
      %   Array KNN_DISTS has size [K,QUERY_DESCRIPTORS_NUM] and value
      %   KNN_DISTS(N,I) is the distance of the N-Nearest descriptor to the
      %   Ith query descriptor.
      %
      %   Array NUM_DESCRIPTORS of size [1, NUM_IMAGES_IN_DB] contains the
      %   number of descriptors extracted from the database images.
      import helpers.*;
      startTime = tic;
      numQueries = dataset.NumQueries;
      k = obj.Opts.k;
      numImages = lastImageNo - firstImageNo + 1;
      queriesKnns = cell(1,numQueries);
      queriesKnnDists = cell(1,numQueries);

      testSignature = obj.getSignature;
      detSignature = featExtractor.getSignature;
      imagesSignature = dataset.getImagesSignature(firstImageNo:lastImageNo);

      % Try to load already computed queries
      isCachedQuery = false(1,numQueries);
      nonCachedQueries = 1:numQueries;
      knnsResKeys = cell(1,numQueries);
      imgsInfoKey = strcat(obj.DatasetChunkInfoPrefix, testSignature,...
          detSignature, imagesSignature);
      cacheResults = featExtractor.UseCache && obj.UseCache;
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
        obj.getDatasetFeatures(dataset,featExtractor,firstImageNo,...
        lastImageNo);

      if cacheResults
        DataCache.storeData(imgsInfoKey,numDescriptors);
      end

      % Compute the KNNs
      helpers.DataCache.disableAutoClear();
      queriesKnnDistsTmp = cell(1,numel(nonCachedQueries)) ;
      queriesKnnsTmp = cell(1,numel(nonCachedQueries)) ;
      parfor qi = 1:numel(nonCachedQueries)
        q = nonCachedQueries(qi) ;
        obj.info('Imgs %d:%d - Computing KNNs for query %d/%d.',...
          firstImageNo,lastImageNo,q,numQueries);
        [knnDescIds, queriesKnnDistsTmp{qi}] = ...
          obj.computeKnn(descriptors, qDescriptors{q});
        queriesKnnsTmp{qi} = imageIdxs(knnDescIds);
        if cacheResults
          DataCache.storeData({queriesKnnsTmp{qi}, queriesKnnDistsTmp{qi}},...
            knnsResKeys{q});
        end
      end
      queriesKnnDists(nonCachedQueries) = queriesKnnDistsTmp ;
      queriesKnns(nonCachedQueries) = queriesKnnsTmp ;
      clear queriesKnnDistsTmp queriesKnnsTmp ;
      helpers.DataCache.enableAutoClear();
      obj.debug('All %d-NN for %d images computed in %gs.',...
        k, numImages, toc(startTime));
    end

    function [knnDescIds, knnDists] = computeKnn(obj, descriptors, ...
        qDescriptors)
      % computeKnn Compute KNN of descriptors
      %   [KNNS_DESC_IDS KNN_DISTS] = computeKnn(DESC_DBASE, Q_DESCS)
      %   computes obj.Opts.K nearest neighbours of each descriptor
      %   Q_DESCS(:,QDID) in the database of extracted descriptors
      %   DESC_DBASE.
      %
      %   KNNS_DESC_IDS is an array of size [K,size(Q_DESCS,2)] where each
      %   value DID = KNNS_DESC_IDS(N,QDID) means that descriptor
      %   DESC_DBASE(:,DID) is the N-Nearest neighbour of descriptor
      %   Q_DESCS(:,QDID) in the database.
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

    function [descriptors imageIdxs numDescriptors] = ...
        getDatasetFeatures(obj, dataset, featExtractor, firstImageNo, lastImageNo)
      % getDatasetFeatures Get all extr. features from the dataset
      %   [DESCS IMAGE_IDXS NUM_DESCS] = obj.getDatasetFeatures(DATASET,
      %   FEAT_EXTRACTOR,FIRST_IMG_NO, LAST_IMG_NO) Retrieves all
      %   extracted descriptors DESCS from images [FIRST_IMG_NO,LAST_IMG_NO]
      %   from the DATASET with FEAT_EXTRACTOR. 
      %   size(DESCS) = [DESC_SIZE,NUM_DESCRIPTORS].
      %
      %   Array IMAGE_IDXS of size(NUM_DESCRIPTORS,1) contain the id of the
      %   image in which the descriptor was calculated. The value
      %   NUM_DESCRIPTORS(1,IMAGE_ID) only gathers the number of extracted
      %   descriptor in an image.
      import helpers.*;
      numImages = lastImageNo - firstImageNo + 1;

      % Retreive features of all images
      detSignature = featExtractor.getSignature;
      obj.info('Computing signatures of %d images.',numImages);
      imagesSignature = dataset.getImagesSignature(firstImageNo:lastImageNo);
      featKeyPrefix = obj.DatasetFeaturesKeyPrefix;
      featuresKey = strcat(featKeyPrefix,detSignature,imagesSignature);
      features = [];
      if featExtractor.UseCache && DataCache.hasData(featuresKey)
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
            featExtractor.extractFeatures(imagePath);
          descriptorsStore{id} = single(descriptorsStore{id});
        end
        helpers.DataCache.enableAutoClear();
        obj.debug('Features computed in %fs.',toc(featStartTime));
        % Put descriptors in a single array
        numDescriptors = cellfun(@(c) size(c,2),descriptorsStore);
        % Handle cases when no descriptors detected
        descriptorSizes = cellfun(@(c) size(c,1),descriptorsStore);
        if descriptorSizes==0
          descriptorsStore{descriptorSizes==0} =...
            single(zeros(max(descriptorSizes),0));
        end
        descriptors = cell2mat(descriptorsStore);
        imageIdxs = arrayfun(@(v,n) repmat(v,1,n),firstImageNo:lastImageNo,...
          numDescriptors,'UniformOutput',false);
        imageIdxs = [imageIdxs{:}];
        
        if featExtractor.UseCache
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
    function ap = rankedListAp(query, rankedList)
    % rankedListAp Calculate average precision of retrieved images
    % AP = rankedListAp(QUERY, RANKED_LIST) Compute average precision of
    %   retrieved images (their ids) by QUERY, sorted by their relevancy in
    %   RANKED_LIST. Average precision is calculated as area under the
    %   precision/recall curve.
    %   This code is recoded method from [2]:
    %   http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/compute_ap.cpp
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

