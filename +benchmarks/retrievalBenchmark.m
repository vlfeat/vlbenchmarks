classdef retrievalBenchmark < benchmarks.genericBenchmark
  %RETREIVALBENCHMARK
  
  properties
    opts;
  end
  
  properties(Constant)
    defK = 100;
    defMaxComparisonsFactor = inf;
    resultsKeyPrefix = 'retreivalResults';
    kdtreeKeyPrefix = 'kdtree_';
  end
  
  methods
    function obj = retrievalBenchmark(varargin)
      obj.benchmarkName = 'RetrBenchmark';
      obj.opts.k = obj.defK;
      obj.opts.maxComparisonsFactor = obj.defMaxComparisonsFactor;
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
      numQueries = dataset.numQueries;
      
      % Retreive features of all images
      frames = cell(numImages,1);
      descriptors = cell(numImages,1);
      featStartTime = tic;
      parfor imgIdx = 1:numImages
        imagePath = dataset.getImagePath(imgIdx);
        [frames{imgIdx} descriptors{imgIdx}] = detector.extractFeatures(imagePath);
      end
      Log.debug(obj.benchmarkName,...
          sprintf('Features obtained in %fs.',toc(featStartTime)));
      
      % Compute the KDTree
      kdtreeKey = strcat(obj.kdtreeKeyPrefix,detector.getSignature(),...
        dataset.getImagesSignature());
      kdtree = DataCache.getData(kdtreeKey);
      if isempty(kdtree)
        Log.info(obj.benchmarkName, ...
          sprintf('Building kdtree of %d features.',allFramesNum));
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
      for q = 1:numQueries
        Log.info(obj.benchmarkName, ...
          sprintf('Computing query %d/%d.',q,numQueries));
        query = dataset.getQuery(q);
        queriesAp(q) = obj.evalQuery(descriptors, kdtree, query);
      end
      
      mAP = mean(queriesAp);
      Log.debug(obj.benchmarkName,...
          sprintf('mAP computed in %fs.',toc(startTime)));
      Log.info(benchmarkName,sprintf('Computed mAP is: %f',mAP));
      
      results = {mAp, queriesAp};
      DataCache.storeData(results, resultsKey);
    end
   
    function [ap rankedList] = evalQuery(obj,descriptors, kdtree, query)
      import helpers.*;
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
      parfor descIdx = 1:qNumDescriptors
        desc = single(qDescriptors(:,descIdx));
        [index, dists(:,descIdx)] = vl_kdtreequery(kdtree, allDescriptors,...
          desc, kdtArgs{:}) ;
        nnImgIds(:,descIdx) = imageIdxs(index);
        Log.trace(benchmarkName,sprintf('Desc. %d done.',descIdx));
      end
      
      votes= vl_binsum( zeros(numImages,1), repmat( dists(end,:), k, 1 ) - dists, nnImgIds );
      [temp, rankedList]= sort( votes./sqrt(numDescriptors), 'descend' ); 
      
      ap = obj.computeAp(query, rankedList);
      
      Log.debug(benchmarkName,...
        sprintf('AP calculated in %fs.',toc(startTime)));
      
      Log.info(benchmarkName,...
        sprintf('Computed average precision is: %f',ap));
      
    end
    
  end
  
  methods(Static)
    
    function ap = computeAp(query, rankedList)
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

