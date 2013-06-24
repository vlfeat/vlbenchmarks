classdef DataMatcher < helpers.Logger &  helpers.GenericInstaller
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here

  properties
    Opts = struct(...
      'matchStrategy','nn',...
      'matchType','OneWay',...
      'kNearest',2,...
      'distMetric','L2');
    StrategiesHandles;
  end

  properties (Constant)
    Strategies = {'all','nn','knn','nnsecondclosest','1to1','1to1secondclosest'};
    MatchTypes = {'OneWay','Mutual','Symmetric'};
  end

  methods
    function obj = DataMatcher(varargin)
      import benchmarks.*;
      import helpers.*;
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      varargin = obj.configureLogger('DataMatcher',varargin);
      obj.checkInstall(varargin);
      obj.StrategiesHandles = containers.Map(...
        obj.Strategies,...
        {@obj.matchAll,...
        @obj.matchNn,...
        @obj.matchKnn,...
        @obj.matchNnSecondClosest,...
        @obj.match1to1,...
        @obj.match1to1SecondClosest});
    end

    function [matches distances] = matchData(obj, data, qData)
      matchingHandle = obj.StrategiesHandles(obj.Opts.matchStrategy);
      [matches distances] = matchingHandle(data,qData);
      if ismember(obj.Opts.matchType,{'Mutual','Symmetric'})
        [matchesBtoA distancesBtoA] = matchingHandle(qData,data);
        matchesBtoA = flipdim(matchesBtoA,1);
      end
      if strcmp(obj.Opts.matchStrategy,'All'), return; end
      switch obj.Opts.matchType
        case 'Mutual'
          % Get the two set intersection
          [matches IA IB] = intersect(matches', matchesBtoA','rows');
          matches = matches';
          distances = [distances(:,IA) distancesBtoA(:,IB)];
        case 'Symmetric'
          % Get the two set union
          [matches IA IB] = union(matches', matchesBtoA','rows');
          matches = matches';
          distances = [distances(:,IA) distancesBtoA(:,IB)];
      end
      obj.info('Found %d matches',size(matches,2));
    end
  end

  methods (Access = protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer(),helpers.VlFeatInstaller('0.9.14'),...
        helpers.YaelInstaller()};
    end
    
    function [srclist flags] = getMexSources(obj)
      path = fullfile('+benchmarks','+helpers','');
      srclist = {fullfile(path,'greedyBipartiteMatching.c')};
      flags = {'',''};
    end

    function [matches distances] = matchAll(obj, data, qData)
      obj.info('Computing cross distances between all data');
      distances = vl_alldist2(single(data),single(qData),...
        obj.Opts.distMetric);
      obj.info('Sorting distances')
      %[distances, perm] = sort(distances(:),'ascend');
      distances = distances(:);
      % Create list of edges in the bipartite graph
      [aIdx bIdx] = ind2sub([size(data,2), size(qData,2)], 1:numel(distances));
      matches = [aIdx;bIdx];
    end

    function [matches distances] = matchNn(obj, data, qData)
      [matches distances] = obj.knn(data, qData, 1);
      matches = [1:size(qData,2);matches];
    end

    function [matches distances] = matchKnn(obj, data, qData)
      [matches distances] = obj.knn(data, qData, obj.Opts.kNearest);
      matches = [1:size(qData,2);matches];
    end

    function [matches distances] = matchNnSecondClosest(obj, data, qData)
      [matches distances] = obj.knn(data, qData, 2);
      matches = [1:size(qData,2);matches(1,:)];
      distances = distances(1,:)./distances(2,:);
    end

    function [matches distances] = match1to1(obj, dataA, dataB)
      import benchmarks.helpers.*;
      [edges dists] = obj.matchAll(dataA, dataB);
      [dists, perm] = sort(dists(:),'ascend');
      edges = edges(:,perm);
      % Find one-to-one best matches
      obj.info('Matching data 1-to-1.');
      matches = greedyBipartiteMatching(size(dataA,2), size(dataB,2), edges');
      matches = [1:size(dataA,2);matches];
      % Remove non-matching edges
      matches = matches(:,matches(2,:)~=0);
      if nargout > 1
        revind(perm) = 1:numel(dists); % Create reverse index
        distances = dists(revind(sub2ind([size(dataA,2), size(dataB,2)],...
          matches(1,:),matches(2,:))));
      end
    end
    
    function [matches distances] = match1to1SecondClosest(obj, dataA, dataB)
      import benchmarks.helpers.*;
      [edges dists] = obj.matchAll(dataA, dataB);
      [dists, perm] = sort(dists(:),'ascend');
      edges = edges(:,perm);
      % Find one-to-one best matches
      obj.info('Matching data 1-to-1.');
      [matches secondClosest] = greedyBipartiteMatching(size(dataA,2), size(dataB,2), edges');
      matches = [1:size(dataA,2);matches];
      % Remove non-match edges
      validMatch = matches(2,:)~=0 & secondClosest~=0;
      matches = matches(:,validMatch);
      secondClosest = secondClosest(:,validMatch);
      if nargout > 1
        revind(perm) = 1:numel(dists); % Create reverse index
        distancesClosest = dists(revind(sub2ind([size(dataA,2), size(dataB,2)],...
          matches(1,:),matches(2,:))));
        distancesSecondClosest = dists(revind(sub2ind([size(dataA,2), size(dataB,2)],...
          matches(1,:),secondClosest(1,:))));
        distances = distancesClosest./distancesSecondClosest;
      end
    end
    
    function [knnDescIds, knnDists] = knn(obj, descriptors, qDescriptors, k)
      import helpers.*;
      obj.info('Computing %d-NN of %d descs in db of %d descs.',...
        k,size(qDescriptors,2),size(descriptors,2));
      distMetric = YaelInstaller.DistMetricParamMap(obj.Opts.distMetric);
      startTime = tic;
      [knnDescIds, knnDists] = yael_nn(single(descriptors), ...
        single(qDescriptors), min(k, size(qDescriptors,2)),distMetric);
      obj.debug('KNN calculated in %fs.',toc(startTime));
    end
  end
end
