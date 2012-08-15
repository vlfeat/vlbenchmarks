classdef retrievalBenchmark < benchmarks.genericBenchmark
  %RETREIVALBENCHMARK
  
  properties
    opts;
  end
  
  properties(Constant)
    defK = 100;
    defMaxComparisonsFactor = inf;
    resultsKeyPrefix = 'retreivalResults';
    kdtreeKeyPrefix = 'kdtree';
    datasetFeaturesKeyPrefix = 'datasetFeatures';
  end
  
  methods
    function obj = retrievalBenchmark(varargin)
      obj.benchmarkName = 'RetrBenchmark';
      obj.opts.k = obj.defK;
      obj.opts.maxComparisonsFactor = obj.defMaxComparisonsFactor;
      obj.opts.maxNumQueries = inf;
      obj.opts = vl_argparse(obj.opts,varargin);
    end
    
    function [mAP queriesAp ] = evalDetector(obj, detector, dataset)
      import helpers.*;
      
      Log.info(obj.benchmarkName,...
        sprintf('Evaluating detector %s on dataset %s.',...
        detector.detectorName, dataset.datasetName));
      startTime = tic;
      
      % Try to load data from cache
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      queriesSignature = dataset.getQueriesSignature();
      resultsKey = strcat(obj.resultsKeyPrefix, detSignature,...
        imagesSignature, queriesSignature);
      results = DataCache.getData(resultsKey);
      if ~isempty(results)
        [mAP, queriesAp] = results{:};
        Log.debug(obj.benchmarkName,'Results loaded from cache.');
        return;
      end
      
      numImages = dataset.numImages;
      numQueries = min([dataset.numQueries obj.opts.maxNumQueries]);
      
      % Retreive features of all images
      featuresKey = strcat(obj.datasetFeaturesKeyPrefix, detSignature,...
        imagesSignature);
      features = DataCache.getData(featuresKey);
      if isempty(features)
        % Compute the features
        frames = cell(numImages,1);
        descriptors = cell(numImages,1);
        featStartTime = tic;
        parfor imgIdx = 1:numImages
          imagePath = dataset.getImagePath(imgIdx);
          [frames{imgIdx} descriptors{imgIdx}] = detector.extractFeatures(imagePath);
        end
        Log.debug(obj.benchmarkName,...
            sprintf('Features computed in %fs.',toc(featStartTime)));
        DataCache.storeData({frames, descriptors},featuresKey);
      else 
        [frames descriptors] = features{:};
        Log.debug(obj.benchmarkName,'Features loaded from cache.');
      end
      
      % Compute the KDTree
      kdtreeKey = strcat(obj.kdtreeKeyPrefix,detector.getSignature(),...
        dataset.getImagesSignature());
      kdtree = DataCache.getData(kdtreeKey);
      if isempty(kdtree)
        allFeaturesNum = size([descriptors{:}],2);
        Log.info(obj.benchmarkName, ...
          sprintf('Building kdtree of %d features.',allFeaturesNum));
        kdStartTime = tic;
        kdtree = vl_kdtreebuild(single([descriptors{:}]));
        Log.debug(obj.benchmarkName,...
          sprintf('Kdtree built in %fs.',toc(kdStartTime)));
        DataCache.storeData(kdtree,kdtreeKey);
      else
        Log.debug(obj.benchmarkName,'Kdtree loaded from cache.');
      end
      
      % Compute average precisions
      queriesAp = zeros(numQueries,1);
      parfor q = 1:numQueries
        Log.info(obj.benchmarkName, ...
          sprintf('Computing query %d/%d.',q,numQueries));
        query = dataset.getQuery(q);
        queriesAp(q) = obj.evalQuery(descriptors, kdtree, query);
      end
      
      mAP = mean(queriesAp);
      Log.debug(obj.benchmarkName,...
          sprintf('mAP computed in %fs.',toc(startTime)));
      Log.info(obj.benchmarkName,sprintf('Computed mAP is: %f',mAP));
      
      results = {mAP, queriesAp};
      DataCache.storeData(results, resultsKey);
    end
   
    function [ap rankedList pr] = evalQuery(obj,descriptors, kdtree, query)
      import helpers.*;
      import benchmarks.*;
      
      startTime = tic;
      benchmarkName = obj.benchmarkName;
      k = obj.opts.k;
      kdtArgs = {'NumNeighbors', k};
      maxCompF = obj.opts.maxComparisonsFactor;
      if ~isinf(maxCompF) && maxCompF > 0
        kdtArgs = [kdtArgs {'MaxComparisons', maxCompF * k}];
      end
      
      qImgId = query.imageId;
      qDescriptors = descriptors{qImgId};
      qNumDescriptors = size(descriptors{qImgId},2);
      allDescriptors = single([descriptors{:}]);
      
      numImages = numel(descriptors);
      numDescriptors = cellfun(@(c) size(c,2),descriptors);
      imageIdxs = arrayfun(@(v,n) repmat(v,1,n),1:numImages, ...
        numDescriptors','UniformOutput',false);
      imageIdxs = [imageIdxs{:}];
      
      dists = zeros(k,qNumDescriptors);
      nnImgIds = zeros(k,qNumDescriptors);
      
      Log.info(benchmarkName,...
        sprintf('Computing %d-nearest neighbours of %d descriptors.',...
        k,qNumDescriptors));
      for descIdx = 1:qNumDescriptors
        desc = single(qDescriptors(:,descIdx));
        [index, dists(:,descIdx)] = vl_kdtreequery(kdtree, allDescriptors,...
          desc, kdtArgs{:}) ;
        nnImgIds(:,descIdx) = imageIdxs(index);
        Log.trace(benchmarkName,sprintf('Desc. %d done.',descIdx));
      end
      
      votes= vl_binsum( zeros(numImages,1), repmat( dists(end,:), k, 1 ) - dists, nnImgIds );
      votes = votes./sqrt(numDescriptors);
      [temp, rankedList]= sort( votes, 'descend' ); 
      
      %ap = retrievalBenchmark.philbinComputeAp(query, rankedList);
      [precision recall info]  = retrievalBenchmark.calcPR(query, votes);
      ap = info.ap;
      pr = {precision recall info};
      
      Log.debug(benchmarkName,...
        sprintf('AP calculated in %fs.',toc(startTime)));
      
      Log.info(benchmarkName,...
        sprintf('Computed average precision is: %f',ap));
      
    end
    
  end
  
  methods(Static)
    
    function [precision recall info] = calcPR(query, scores)
      y = - ones(1, numel(scores)) ;
      y(query.good) = 1 ;
      y(query.ok) = 1 ;
      y(query.junk) = 0 ;
      y(query.imageId) = 0 ; % ooops ?

      [precision recall info] = vl_pr(y, scores);
    end
    
    function ap = philbinComputeAp(query, rankedList)
      oldRecall = 0.0;
      oldPrecision = 1.0;
      ap = 0.0;

      ambiguous = query.junk;
      positive = [query.good;query.ok];
      
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

