classdef retrievalBenchmark < benchmarks.genericBenchmark ...
    & helpers.GenericInstaller
  %RETREIVALBENCHMARK
  
  properties
    opts;
  end
  
  properties(Constant)
    defK = 50;
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
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.configureLogger(obj.benchmarkName,varargin);
    end
    
    function [res] = findApproxFactor(obj, detector, dataset)
      import helpers.*;
      
      % Get image features
      [frames descriptors] = obj.getAllDatasetFeatures(dataset, detector);
      
      % Get first N descriptors
      qFeatNum = 10000;
      featNum =  100000;
      descriptors = [descriptors{:}]; 
      randSelection = randsample(size(descriptors,2),featNum);
      size(descriptors)
      descriptors = descriptors(:,randSelection);
      queryDescs = single(descriptors(:,1:qFeatNum));
      dbDescriptors = single(descriptors(:,qFeatNum+1:featNum));
      clear frames;
      clear descriptors;
      
      obj.info('Building kdtree on %d features.',size(dbDescriptors,2));
      kdStartTime = tic;
      kdtree = vl_kdtreebuild(single(dbDescriptors));
      obj.debug('Kdtree built in %fs.',toc(kdStartTime));
      
      k = obj.opts.k;
      obj.info('Computing ground truth.',size(dbDescriptors,2));
      [indexes, dists] = obj.yaelKnn(dbDescriptors, queryDescs, k);
      %[indexes, dists] = vl_kdtreequery(kdtree,dbDescriptors,queryDescs,...
      %    'NumNeighbors', k);
      
      maxNumSteps = 10;
      minApproxF = 1;
      maxApproxF = 100;
      
      appFactors = linspace(1,150,20);
      maxNumSteps = numel(appFactors);
      
      
      approxFactors = zeros(1,maxNumSteps);
      missingFeatRatio = zeros(1,maxNumSteps);
      idxError = zeros(1,maxNumSteps);
      featDistRatio = zeros(1,maxNumSteps);
      distRatio = zeros(1,maxNumSteps);
      
      
      for i = 1:maxNumSteps
        %approxFactor = (maxApproxF - minApproxF) / 2;
        approxFactor = appFactors(i);
        obj.info('Computing approx with f=%f',approxFactor);
        [appIdxs, appDists] = vl_kdtreequery(kdtree,dbDescriptors,queryDescs,...
          'NumNeighbors', k, 'MaxComparisons',k*approxFactor);
        for j = 1:qFeatNum
          [isfnd locs] = ismember(appIdxs(:,j),indexes(:,j));
          missingFeatRatio(i) = missingFeatRatio(i) + k - sum(isfnd);
        
          matches = locs(locs~=0);
          mAppDists = appDists(isfnd);
          mDists = dists(matches);
        
          errs = mDists(mAppDists ~= 0)./mAppDists(mAppDists ~= 0);
          featDistRatio(i) = featDistRatio(i) + sum(errs)/k;
        end
        
        missingFeatRatio(i) = missingFeatRatio(i) / qFeatNum;
        featDistRatio(i) = featDistRatio(i) / qFeatNum;
        
        idxError(i) = mean(mean(appIdxs ~= indexes));
        
        distRatio(i) = mean(mean(dists(appDists ~= 0) ./ appDists(appDists ~= 0)));
      end
      
      figure(1); clf; grid on; hold on;
      plot(appFactors, missingFeatRatio); title('Number of missing features per query');
      
      figure(2); clf; grid on; hold on;
      plot(appFactors, featDistRatio); title('Average distance ratio between same features');

      figure(3); clf; grid on; hold on;
      plot(appFactors, idxError); title('% of wrong indexes');
      
      
      figure(4); clf; grid on; hold on;
      plot(appFactors, distRatio); title('Distance ratio');
      
      res = {appFactors,missingFeatRatio,featDistRatio,idxError,distRatio};
      
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
      
      % Retreive features of all images
      [frames descriptors] = obj.getAllDatasetFeatures(dataset, detector);
      
      % Compute the KDTree
      %kdtreeKey = strcat(obj.kdtreeKeyPrefix,detector.getSignature(),...
      %  dataset.getImagesSignature());
      %kdtree = DataCache.getData(kdtreeKey);
      %if isempty(kdtree)
      %  allFeaturesNum = size([descriptors{:}],2);
      %  obj.info('Building kdtree of %d features.',allFeaturesNum);
      %  kdStartTime = tic;
      %  kdtree = vl_kdtreebuild(single([descriptors{:}]));
      %  obj.debug('Kdtree built in %fs.',toc(kdStartTime));
      %  DataCache.storeData(kdtree,kdtreeKey);
      %else
      %  obj.debug(obj.benchmarkName,'Kdtree loaded from cache.');
      %end
      kdtree = [];
      
      % Compute average precisions
      numQueries = min([dataset.numQueries obj.opts.maxNumQueries]);
      queriesAp = zeros(numQueries,1);
      parfor q = 1:numQueries
        obj.info('Computing query %d/%d.',q,numQueries);
        query = dataset.getQuery(q);
        queriesAp(q) = obj.evalQuery(frames, descriptors, kdtree, query);
      end
      
      mAP = mean(queriesAp);
      obj.debug('mAP computed in %fs.',toc(startTime));
      obj.info('Computed mAP is: %f',mAP);
      
      results = {mAP, queriesAp};
      DataCache.storeData(results, resultsKey);
    end
   
    function [ap rankedList pr] = evalQuery(obj, frames, descriptors, kdtree, query)
      import helpers.*;
      import benchmarks.*;
      
      startTime = tic;
      k = obj.opts.k;
      kdtArgs = {'NumNeighbors', k};
      maxCompF = obj.opts.maxComparisonsFactor;
      if ~isinf(maxCompF) && maxCompF > 0
        kdtArgs = [kdtArgs {'MaxComparisons', maxCompF * k}];
      end
      
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
      %[indexes, dists] = vl_kdtreequery(kdtree, allDescriptors,...
      %  qDescriptors, kdtArgs{:}) ;
      [indexes, dists] = obj.yaelKnn(allDescriptors, qDescriptors, k);
      
      nnImgIds = imageIdxs(indexes);
      
      votes= vl_binsum( single(zeros(numImages,1)),...
        repmat( dists(end,:), min(k,qNumDescriptors), 1 ) - dists,...
        nnImgIds );
      votes = votes./sqrt(numDescriptors);
      [temp, rankedList]= sort( votes, 'descend' ); 
      
      %ap = retrievalBenchmark.philbinComputeAp(query, rankedList);
      [precision recall inf]  = retrievalBenchmark.calcPR(query, votes);
      ap = inf.ap;
      pr = {precision recall inf};
      
      obj.debug('AP calculated in %fs.',toc(startTime));
      
      obj.info('Computed average precision is: %f',ap);
      
    end
    
    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.opts);
    end
    
    function [frames descriptors] = getAllDatasetFeatures(obj,dataset, detector)
      import helpers.*;
      numImages = dataset.numImages;
      
      % Retreive features of all images
      detSignature = detector.getSignature;
      imagesSignature = dataset.getImagesSignature();
      featKeyPrefix = obj.datasetFeaturesKeyPrefix;
      featuresKey = strcat(featKeyPrefix, detSignature,imagesSignature);
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
        obj.debug('Features computed in %fs.',toc(featStartTime));
        DataCache.storeData({frames, descriptors},featuresKey);
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
      y(query.imageId) = 0 ; % ooops ?

      [precision recall info] = vl_pr(y, scores);
    end
    
    function [indexes dists] = yaelKnn(features, qFeatures, k)
      yaelPath = fullfile('data','software','yael_v277','matlab','');
      addpath(yaelPath);
      [indexes, dists] = yael_nn(single(features), single(qFeatures), ...
        min(k, size(qFeatures,2)));
      rmpath(yaelPath);
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
    
    function deps = getDependencies()
      deps = {helpers.Installer(),benchmarks.helpers.Installer()};
    end
  end  
end

