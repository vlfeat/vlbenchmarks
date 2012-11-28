classdef RetrievalBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
% benchmarks.RetrievalBenchmark KNN Retrieval benchmark
%   benchmarks.RetrievalBenchmark('OptionName',optionValue,...)
%   constructs an object to compute the feature extractor performance in a 
%   simple image retrieval system setting [1] based on K-Nearest Neighbours
%   (KNN).
%
%   This class implements simple retrieval system based on [1] and then
%   tests its performance when features extracted by a certain algorithm
%   are used. The main performance measure is Mean Average Precision (mAP)
%   introduced in [2] computed over their image dataset which is wrapped
%   in class datasets.VggRetrievalDataset.
%
%   RETRIEVAL SYSTEM
%
%   Descriptor database contain IM_NUM images where each image IMID (image 
%   id, number of the image in the dataset) is described by 
%   IM_DESCS_NUM(IMID) descriptors. The whole database of descriptors 
%   DDBASE is of size [DESC_SIZE, DESCS_NUM]. The image in which the
%   descriptor DESC_DBASE(:,DESC_ID) was detected is denoted as
%   DESC_IMG_ID(DESC_ID). Its reverse mapping, i.e. IDs of descriptors
%   detected in an image is denoted as IMG_DESC_IDS(IMG_ID).
%
%   For each query Q_ID from the dataset we obtain the set of query 
%   descriptors Q_DESCS which were detected in the query bounding box.
%   For each query descriptor Q_DESC = Q_DESCS(:,Q_DESC_ID) we look for 
%   K-nearest  neighbours (see option 'K' for setting this parameter) 
%   Q_KNN such that Q_KNN(N,Q_DESC_ID) = DESC_ID means that
%   descriptor DESC = DDBASE(:,DESC_ID) is the N-th closest neighbour to
%   the query descriptor Q_DESC. The distance between those descriptors is
%   noted as Q_KNN_DISTS(N,Q_DESC_ID) = dist(Q_DESC,DESC). 
%   Distance metric can be adjusted with option 'DistMetric'.
%
%   In [1] it was observed that there is some regularity in the descriptor
%   distances. Therefore a simple voting criterion expressed as 'how much
%   closer the Nth descriptor is to the query descriptor than the Kth
%   descriptor'. It can be expressed as
%
%   DIST_DIFF(N,Q_DESC_ID) = Q_KNN_DISTS(N,Q_DESC_ID) - Q_KNN_DISTS(N,Q_DESC_ID);
%
%   Then each retrieved descriptor DESC votes to its image where it
%   originates with a vote equal to its DIST_DIFF value. The voting score
%   of each dataset image IMG_ID is then computed as:
%
%   IS_IMG_DESC = ismember(Q_KNN,IMG_DESC_IDS(IMG_ID)); 
%   RAW_VOTES(IMG_ID) = sum(sum(DIST_DIFF(IS_IMG_ID_DESC)));
%
%   These votes are also further normalised by number of descriptors in
%   image IMG_DESCS_NUM = NUM_DESCRIPTORS(IMG_ID) and also by the number 
%   of query descriptors Q_DESCS_NUM = size(Q_DESCS,2):
%
%   VOTES(IMG_ID) = RAW_VOTES(IMG_ID)/sqrt(IMG_DESCS_NUM)/sqrt(Q_DESCS_NUM)
%
%   Based on those votes ranked list RANKED_LIST of the retrieved image is
%   created as image ids sorted by their (descending) score.
%
%   PERFORMANCE EVALUATION
%
%   For the feature extraction algorithm evaluation, mean average precision
%   of its retrieval system is computed as an area under the
%   precision-recall curve.
%
%   For each query the images in the dataset are divided into three subsets,
%   relevant images (containing images from 'Good' and 'Ok' query subset),
%   ignored images ('Junk' subset) and irrelevant (wrong) images which
%   contain the rest of the images from the dataset.
%
%   Going through the RANKED_LIST of the retrieved images, precision of the
%   retrieval system which would return only first N images is calculated
%   as:
%
%   NUM_REL = Num relevant images in RANKED_LIST(1:N)
%
%                       Precision(N) = NUM_REL/N
%
%   I.e. how precise this limited retrieval system is. And recall is 
%   calculated as:
%
%                Recall(N) = NUM_REL/Num relevant images
%
%   I.e. what fraction of the searched images it had really found.
%
%   The area under the precision/recall curve is calculated using
%   trapezoidal rule.
%
%   The mean average precision is calculated as a mean of all dataset 
%   queries average precision.
%
%   Object constructor accepts the following options:
%
%   K :: 50
%     Number of descriptor nearest neighbours used for the retrieval.
%
%   DistMetric :: 'L2'
%     Distance metric used by the KNN algorithm expressed as its string
%.     name. See helpers.YaelInstaller for available options.
%
%   MaxNumImagesPerSearch :: 1000
%     Maximal number of images which descriptors are in the database. If the
%     number of images in dataset is bigger, it is divided into several
%     chunks. Decrease this number if your computer is runing out of 
%     memory. Set to inf to disable division of the dataset into chunks.
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
%
% See also: helpers.YaelInstaller

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
    ResultsKeyPrefix = 'retreivalResults.';
    % Key prefix for KNN computation results (most time consuming)
    QueryKnnsKeyPrefix = 'retreivalQueryKnns';
    % Key prefix for additional information about the detector features
    DatasetChunkInfoPrefix = 'datasetChunkInfo';
  end

  methods
    function obj = RetrievalBenchmark(varargin)
      import helpers.*;
      obj.BenchmarkName = 'RetrBenchmark';
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end

    function [mAP, info] = ...
        testFeatureExtractor(obj, featExtractor, dataset)
      % testFeatureExtractor Test image feature extractor in a retrieval test
      %   MAP = obj.testFeatureExtractor(FEAT_EXTRACTOR, DATASET) Compute 
      %   mean average precision of a detector in the retrieval test.
      %   FEAT_EXTRACTOR must be a subclass of
      %   localFeatures.GenericLocalFeatureExtractor and must be able to
      %   compute both feature frames and their descriptors. DATASET must
      %   be an object of datasets.VggRetrievalDataset class.
      %
      %   [MAP INFO] = obj.testFeatureExtractor(DETECTOR, DATASET) 
      %   returns an additiona structure INFO with the following members:
      %
      %   info.queriesAp::
      %     average precision of a detector per a single query
      %
      %   info.rankedList::
      %     array of size [DATASET.NumImages, DATASET.NumQueries] where
      %     each info.rankedList(:,QUERY_NUM) contain IDs of images from 
      %     the dataset retrieved with query QUERY_NUM and ranked by the 
      %     voting score which is stored in info.votes(:,QUERY_NUM).
      %
      %   info.votes::
      %     voting score for each image in info.rankedList.
      %
      %   info.numDescriptors::
      %     array of size [1 DATASET.NumImages] storing the number of 
      %     descriptors per each dataset image.
      %
      %   info.numQueryDescriptors
      %     array of size [q DATASET.NumQueries] storing the number of
      %     descriptors per query.
      %
      %   See also: datasets.VggRetrievalDataset
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
          [mAP, info]=results{:};
          obj.debug('Results loaded from cache.');
          return;
        end
      end
      % Divide the dataset into chunks
      imgsPerChunk = min(obj.Opts.maxNumImagesPerSearch,numImages);
      numChunks = ceil(numImages/imgsPerChunk);
      knns = cell(numChunks,1); % as image indexes
      knnDists = cell(numChunks,1);
      numDescriptors = cell(1,numChunks);
      obj.info('Dataset has been divided into %d chunks.',numChunks);

      % Load query descriptors
      queryDescriptors = obj.gatherQueriesDescriptors(dataset, featExtractor);
      numQueryDescriptors = cellfun(@(a) size(a,2),queryDescriptors);

      % Compute KNNs for all image chunks
      for chNum = 1:numChunks
        firstImageNo = (chNum-1)*imgsPerChunk+1;
        lastImageNo = min(chNum*imgsPerChunk,numImages);
        [knns{chNum}, knnDists{chNum}, numDescriptors{chNum}] = ...
          obj.computeKnns(dataset,featExtractor,queryDescriptors,...
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

      info = struct('queriesAp',queriesAp,'rankedList',rankedLists,...
        'votes',votes, 'numDescriptors',numDescriptors,...
        'numQueryDescriptors',numQueryDescriptors);

      results = {mAP, info};
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
        bbox = query.box + 1;
        imgPath = dataset.getImagePath(query.imageId);
        [qFrames qDescriptors{q}] = featExtractor.extractFeatures(imgPath);
        % Pick only features in the query box
        visibleFrames = ...
          bbox(1) < qFrames(1,:) & ...
          bbox(2) < qFrames(2,:) & ...
          bbox(3) > qFrames(1,:) & ...
          bbox(4) > qFrames(2,:) ;
        qDescriptors{q} = qDescriptors{q}(:,visibleFrames);
        obj.info('Query %d: %d features.',q,size(qDescriptors{q},2));
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

      if isempty(knnImgIds)
        numImages = numel(numDescriptors);
        ap = 0; rankedList = zeros(numImages,1); 
        votes = zeros(numImages,1); return;
      end

      k = obj.Opts.k;
      numImages = numel(numDescriptors);
      qNumDescriptors = size(knnImgIds,2);

      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( knnDists(end,:), min(k,qNumDescriptors), 1 ) - knnDists,...
        knnImgIds );
      votes = votes./sqrt(max(numDescriptors',1))./sqrt(max(qNumDescriptors,1));
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
        knnDescIds = zeros(k,0);
        knnDists = zeros(k,0);
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
    end
  end

  methods (Access = protected)
    function deps = getDependencies(obj)
      import helpers.*;
      deps = {Installer(),benchmarks.helpers.Installer(),...
        VlFeatInstaller('0.9.15'),YaelInstaller()};
    end
  end

  methods(Static)
    function [ap recall precision] = rankedListAp(query, rankedList)
      % rankedListAp Calculate average precision of retrieved images
      %   AP = rankedListAp(QUERY, RANKED_LIST) Compute average precision 
      %   of retrieved images (their ids) by QUERY, sorted by their 
      %   relevancy in RANKED_LIST. Average precision is calculated as 
      %   area under the precision/recall curve.
      %
      %   [AP RECALL PRECISION] = rankedListAp(...) Return also precision
      %   recall values.

      % make sure each image appears at most once in the rankedList
      [temp,inds]=unique(rankedList,'first');
      rankedList= rankedList( sort(inds) );

      numImages = numel(rankedList);
      labels = - ones(1, numImages);
      labels(query.good) = 1;
      labels(query.ok) = 1;
      labels(query.junk) = 0;
      labels(query.imageId) = 1;
      rankedLabels = labels(rankedList);

      [recall precision info] = vl_pr(rankedLabels, numImages:-1:1);
      ap = info.auc;
    end
  end  
end

