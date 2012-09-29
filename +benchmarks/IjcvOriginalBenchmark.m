classdef IjcvOriginalBenchmark < benchmarks.GenericBenchmark ...
    & helpers.GenericInstaller & helpers.Logger
% benchmarks.IjcvOriginalBenchmark IJCV05 affine detectors test 
%   benchmarks.IjcvOriginalBenchmark('OptionName',OptionValue,...) Constructs
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
%   CommonPart :: [1]
%     flag should be set to 1 for repeatability and 0 for descriptor 
%     performance
%
%   REFERENCES
%   [1] K. Mikolajczyk, T. Tuytelaars, C. Schmid, A. Zisserman,
%       J. Matas, F. Schaffalitzky, T. Kadir, and L. Van Gool. A
%       comparison of affine region detectors. IJCV, 1(65):43–72, 2005.

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  
  properties
    % Object options
    Opts = struct(...
      'overlapError', 0.4,...
      'commonPart', 1);
  end
  
  properties (Constant, Hidden)
    % Installation directory
    InstallDir = fullfile('data','software','repeatability','');
    % Cache key prefix for storing the results
    KeyPrefix = 'kmEval';
    % Prefixes for particular results
    TestTypeKeys = {'rep','rep+match'};
    % URL Address of the test source code
    Url = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz';
  end
  
  methods
    function obj = IjcvOriginalBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      
      obj.BenchmarkName = 'IjcvOriginalBenchmark'; 
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      
      % Index of a value from the test results corresponding to idx*10 overlap
      % error. Original benchmark computes only overlap errors in step of 0.1
      overlapErr = obj.Opts.overlapError;
      overlapErrIdx = round(overlapErr*10);
      if (overlapErr*10 - overlapErrIdx) ~= 0
          obj.warn(['IJCV affine benchmark supports only limited set of overlap errors. ',...
             'Your overlap error was rounded.']);
      end
       
      varargin = obj.configureLogger(obj.BenchmarkName,varargin);
      obj.checkInstall(varargin);
    end
    
    function [repScore, numCorresp, matchScore, numMatches] = ...
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
        if nargout == 4
          obj.info('Comparing frames and descriptors from det. %s and images %s and %s.',...
            featExtractor.Name,getFileName(imageAPath),getFileName(imageBPath));
          [framesA descriptorsA] = featExtractor.extractFeatures(imageAPath);
          [framesB descriptorsB] = featExtractor.extractFeatures(imageBPath);
          [repScore, numCorresp, matchScore, numMatches] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, ...
                             framesA, framesB, descriptorsA, descriptorsB);
        else
          obj.info('Comparing frames from det. %s and images %s and %s.',...
            featExtractor.Name,getFileName(imageAPath),getFileName(imageBPath));
          [framesA] = featExtractor.extractFeatures(imageAPath);
          [framesB] = featExtractor.extractFeatures(imageBPath);
          [repScore, numCorresp] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, framesA, framesB);
          matchScore = -1;
          numMatches = -1;
        end
        if featExtractor.UseCache
          results = {repScore numCorresp matchScore numMatches};
          obj.storeResults(results, resultsKey);
        end
      else
        obj.debug('Results loaded from cache');
        [repScore numCorresp matchScore numMatches] = cachedResults{:};
      end
      
    end

    function [repScore numCorresp matchScore numMatches] = ... 
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
     
      krisDir = IjcvOriginalBenchmark.InstallDir;
      tmpFile = tempname;
      ellBFile = [tmpFile 'ellB.txt'];
      tmpHFile = [tmpFile 'H.txt'];
      ellAFile = [tmpFile 'ellA.txt'];
      ellAFrames = localFeatures.helpers.frameToEllipse(framesA);
      ellBFrames = localFeatures.helpers.frameToEllipse(framesB);
      localFeatures.helpers.writeFeatures(ellAFile,ellAFrames, descriptorsA);
      localFeatures.helpers.writeFeatures(ellBFile,ellBFrames, descriptorsB);
      H = tf;
      save(tmpHFile,'H','-ASCII');
      overlap_err_idx = round(obj.Opts.overlapError*10);

      addpath(krisDir);
      rehash;
      [err, tmprepScore, tmpnumCorresp, matchScore, numMatches] ...
          = repeatability(ellAFile,ellBFile,tmpHFile,imageAPath,...
              imageBPath,obj.Opts.commonPart);
      rmpath(krisDir);

      repScore = tmprepScore(overlap_err_idx)./100;
      numCorresp = tmpnumCorresp(overlap_err_idx);
      matchScore = matchScore ./ 100;
      delete(ellAFile);
      delete(ellBFile);
      delete(tmpHFile);
      
      obj.info('Repeatability: %g \t Num correspondences: %g',repScore,numCorresp);
      
      obj.info('Match score: %g \t Num matches: %g',matchScore,numMatches);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',...
        size(framesA,2),size(framesB,2),timeElapsed);
    end

    function signature = getSignature(obj)
      signature = helpers.struct2str(obj.Opts);
    end
  end

  methods (Access = protected, Hidden)
    function deps = getDependencies(obj)
      deps = {helpers.Installer(),benchmarks.helpers.Installer()};
    end

    function [srclist flags] = getMexSources(obj)
      import benchmarks.*;
      path = IjcvOriginalBenchmark.InstallDir;
      srclist = {fullfile(path,'c_eoverlap.cxx')};
      flags = {''};
    end

    function [Urls dstPaths] = getTarballsList(obj)
      import benchmarks.*;
      Urls = {IjcvOriginalBenchmark.Url};
      dstPaths = {IjcvOriginalBenchmark.InstallDir};
    end
  end
end

