classdef PamiDescBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
% benchmarks.PamiDescBenchmark IJCV05 affine detectors test 
%   benchmarks.PamiDescBenchmark('OptionName',OptionValue,...) Constructs
%   an object which wraps around Kristian's testing script of affine covariant
%   image regions (frames). Calls directly 'repeatability.m' script.
%
%   Script used is available on:
%   http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz
%
%   Options:
%
%   OverlapError :: [0.4]
%     Overlap error of the ellipses for which the repScore is
%     calculated. Can be only in {0.1, 0.2, ... ,0.9}.
%
%   REFERENCES
%   [1] K. Mikolajczyk, C. Schmid,
%       A Performance Evaluation of Local Descriptors. PAMI, 
%       27(10):1615–1630, 2005.

% Authors: Karel Lenc

% AUTORIGHTS
  
  properties
    % Object options
    Opts = struct(...
      'overlapError', 0.5,...
      'matchingStrategy','nn');
  end
  
  properties (Constant, Hidden)
    % Installation directory
    InstallDir = fullfile('data','software','repeatability','');
    % Available descriptor matching strategies
    MatchingStrategies = {'threshold','nn','nn-dist-ratio'};
    % Cache key prefix for storing the results
    KeyPrefix = 'kmDescEval';
    % URL Address of the test source code
    Url = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz';
  end
  
  methods
    function obj = PamiDescBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      
      obj.BenchmarkName = 'PamiDescBenchmark'; 
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      
      % Index of a value from the test results corresponding to idx*10 overlap
      % error. Original benchmark computes only overlap errors in step of 0.1
      overlapErr = obj.Opts.overlapError;
      overlapErrIdx = round(overlapErr*10);
      if (overlapErr*10 - overlapErrIdx) ~= 0
          obj.warn(['PAMI desc. benchmark supports only limited set of overlap errors. ',...
             'Your overlap error was rounded.']);
      end
       
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end
    
    function [precision recall info] = ...
        testFeatureExtractor(obj, featExtractor, tf, imageAPath, imageBPath)
      % testFeatureExtractor Compute repeatability and matching score.
      %   [REP NUM_CORR MATCHING NUM_MATCHES] = obj.testFeatureExtractor(
      %   FEAT_EXTRACTOR, TF, IMAGEA_PATH, IMAGEB_PATH) Compute repeatability
      %   REP and matching score MATCHING of feature extractor FEAT_EXTRACTOR
      %   and its frames and descriptors extracted from images defined by
      %   their path IMAGEA_PATH and IMAGEB_PATH whose geometry is related by
      %   homography TF. NUM_CORR is number of found correspondences and
      %   NUM_MATHCES number of matching detected features. This function
      %   caches results. FEAT_EXTRACTOR must be a subclass of
      %   localFeatures.GenericLocalFeatureExtractor.
      %
      %   [REP NUM_CORR] = obj.testFeatureExtractor(FEAT_EXTRACTOR, TF, 
      %     IMAGEA_PATH, IMAGEB_PATH) Compute only repeatability of the 
      %   image features extractor based only on detected frames.
      import helpers.*;
      import benchmarks.*;
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      resultsKey = cell2str({obj.KeyPrefix, nargout, obj.getSignature(),...
        featExtractor.getSignature(), imageASign, imageBSign});
      cachedResults = obj.loadResults(resultsKey);
      
      % When detector does not cache results, do not use the cached data
      if isempty(cachedResults) || ~featExtractor.UseCache
        obj.info('Comparing frames and descriptors from det. %s and images %s and %s.',...
          featExtractor.Name,getFileName(imageAPath),getFileName(imageBPath));
        [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
        [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
        [precision, recall, info] = ...
          obj.testFeatures(tf, imageAPath, imageBPath, ...
                           framesA, framesB, descriptorsA, descriptorsB);
        if featExtractor.UseCache
          results = {precision, recall, info};
          obj.storeResults(results, resultsKey);
        end
      else
        obj.debug('Results loaded from cache');
        [precision, recall, info] = cachedResults{:};
      end
      
    end

    function [precision recall info] = ... 
               testFeatures(obj, tf, imageAPath, imageBPath, ...
                 framesA, framesB, descriptorsA, descriptorsB)
      % TestFeatures Compute scores of image features
      %   [REP NUM_CORR MATCHING NUM_MATCHES] = obj.testFeatures(TF,
      %   IMAGEA_PATH, IMAGEB_PATH, FRAMES_A, FRAMES_B, DESCRIPTORS_A,
      %   DESCRIPTORS_B) Compute repeatability REP and matching MATHICNG score
      %   between FRAMES_A and FRAMES_B which are related by homography TF and
      %   their descriptors DESCRIPTORS_A and DESCRIPTORS_B which were
      %   extracted from images IMAGE_A and IMAGE_B.
      %
      %   [REP NUM_CORR] = obj.testFeatures(TF, IMAGEA_PATH,
      %   IMAGEB_PATH, FRAMES_A, FRAMES_B) Compute only repeatability
      %   between the the frames FRAMES_A and FRAMES_B.
      import benchmarks.*;
      import helpers.*;
      
      obj.info('Computing kri benchmark between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      
      startTime = tic;
      
      if nargout == 4 && ~exist('descriptorsB','var') 
        obj.warn('Unable to calculate match score without descriptors.');
      end
      
      if nargout == 2
        descriptorsA = [];
        descriptorsB = [];
      end
     
      krisDir = PamiDescBenchmark.InstallDir;
      tmpFile = tempname;
      ellBFile = [tmpFile 'ellB.txt'];
      tmpHFile = [tmpFile 'H.txt'];
      ellAFile = [tmpFile 'ellA.txt'];
      ellAFrames = localFeatures.helpers.frameToEllipse(framesA);
      ellBFrames = localFeatures.helpers.frameToEllipse(framesB);
      localFeatures.helpers.writeFeatures(ellAFile,ellAFrames, descriptorsA);
      localFeatures.helpers.writeFeatures(ellBFile,ellBFrames, descriptorsB);
      H = tf.homography;
      save(tmpHFile,'H','-ASCII');
      overlap_err_idx = round(obj.Opts.overlapError*10);

      addpath(krisDir);
      rehash;
      [err, tmprepScore, tmpnumCorresp, matchScore, numMatches, twi] = ...
          repeatability(ellAFile,ellBFile,tmpHFile,imageAPath,...
              imageBPath,0);
            
      repScore = tmprepScore(overlap_err_idx)./100;
      numCorresp = tmpnumCorresp(overlap_err_idx);
      matchScore = matchScore ./ 100;
            
      [correctMatchNn,totalMatchNn,correctMatchSim,totalMatchSim,correctMatchRn,totalMatchRn] = ...
        descperf(ellAFile,ellBFile,tmpHFile,imageAPath,...
              imageBPath, numCorresp,twi);
            
      rmpath(krisDir);

      delete(ellAFile);
      delete(ellBFile);
      delete(tmpHFile);
      
      switch obj.Opts.matchingStrategy
        case 'nn'
          correctMatch = correctMatchNn;
          totalMatch = totalMatchNn;
        case 'threshold'
          correctMatch = correctMatchSim;
          totalMatch = totalMatchSim;
          % In case of threshold-based matching the number of
          % correspondeces is not based on 1to1 matching.
          numCorresp = sum(twi(:));
        case 'nn-dist-ratio'
          correctMatch = correctMatchRn;
          totalMatch = totalMatchRn;
      end
      
      % Ground truth is the number of correspondences
      recall = correctMatch / numCorresp;
      % Classification is done by matching descriptors
      precision = correctMatch ./ totalMatch;
      
      info = struct('repScore',repScore, 'numCorresp', numCorresp, ...
        'matchScore', matchScore, 'numMatches', numMatches);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',...
        size(framesA,2),size(framesB,2),timeElapsed);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end
  end

  methods (Access = protected, Hidden)

    function [srclist flags] = getMexSources(obj)
      import benchmarks.*;
      path = PamiDescBenchmark.InstallDir;
      srclist = {fullfile(path,'descdist.cxx')};
      flags = {''};
    end

    function [Urls dstPaths] = getTarballsList(obj)
      import benchmarks.*;
      Urls = {PamiDescBenchmark.Url};
      dstPaths = {PamiDescBenchmark.InstallDir};
    end
  end
end

