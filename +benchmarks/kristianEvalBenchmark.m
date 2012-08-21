classdef kristianEvalBenchmark < benchmarks.genericBenchmark & helpers.GenericInstaller
  %KRISTIANEVALBENCHMARK Kristians Mikolajczyk's affine detectors test
  %   Implements test interface for Kristian's testing script of affine
  %   covarinat image regions (frames).
  %
  %   Options:
  %
  %   OverlapError :: [0.4]
  %     Overlap error of the ellipses for which the repScore is
  %     calculated. Can be only in {0.1, 0.2, ... ,0.9}.
  %
  
  properties
    opts                % Options of the km eval
  end
  
  properties (Constant)
    defOverlapError = 0.4;
    installDir = fullfile('data','software','repeatability','');
    keyPrefix = 'kmEval';
    testTypeKeys = {'rep','rep+match'};
    url = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/repeatability.tar.gz';
  end
  
  methods
    function obj = kristianEvalBenchmark(varargin)
      import benchmarks.*;
      import helpers.*;
      
      obj.benchmarkName = 'kristian_eval'; 
      
      obj.opts.overlapError = kristianEvalBenchmark.defOverlapError;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      
      % Index of a value from the test results corresponding to idx*10 overlap
      % error. Kristian eval. computes only overlap errors in step of 0.1
      overlapErr = obj.opts.overlapError;
      overlapErrIdx = round(overlapErr*10);
      if (overlapErr*10 - overlapErrIdx) ~= 0
          obj.warn(['KM benchmark supports only limited set of overlap errors. ',...
             'Your overlap error was rounded.']);
      end
       
      obj.configureLogger(obj.benchmarkName,varargin);
      
      if(~obj.isInstalled())
        obj.warn('Kristian''s benchmark not found, installing dependencies...');
        obj.installDeps();
      end   
    end
    
    function [repScore, numCorresp, matchScore, numMatches] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)
      import helpers.*;
      import benchmarks.*;
      
      obj.info('Comparing frames from det. %s and images %s and %s.',...
          detector.detectorName,getFileName(imageAPath),getFileName(imageBPath));
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageBPath);
      detSign = detector.getSignature();
      testType = kristianEvalBenchmark.testTypeKeys{nargout/2};
      keyPrefix = kristianEvalBenchmark.keyPrefix;
      resultsKey = strcat(keyPrefix,testType,detSign,imageASign,imageBSign);
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        if nargout == 4
          [framesA descriptorsA] = detector.extractFeatures(imageAPath);
          [framesB descriptorsB] = detector.extractFeatures(imageBPath);
          [repScore, numCorresp, matchScore, numMatches] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, ...
                             framesA, framesB, descriptorsA, descriptorsB);
        else
          [framesA] = detector.extractFeatures(imageAPath);
          [framesB] = detector.extractFeatures(imageBPath);
          [repScore, numCorresp] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, framesA, framesB);
          matchScore = -1;
          numMatches = -1;
        end
        
        results = {repScore numCorresp matchScore numMatches};
        DataCache.storeData(results, resultsKey);
      else
        obj.debug('Results loaded from cache');
        
        [repScore numCorresp matchScore numMatches] = cachedResults{:};
      end
      
    end

    function [repScore numCorresp matchScore numMatches] = ... 
               testFeatures(obj, tf, imageAPath, imageBPath, ...
                 framesA, framesB, descriptorsA, descriptorsB)
      
      import benchmarks.*;
      import helpers.*;
      
      obj.info('Computing kristian eval benchmark between %d/%d frames.',...
          size(framesA,2),size(framesB,2));
      
      startTime = tic;
      
      if nargout == 4 && nargin == 8
        commonPart = 0;
      elseif nargout == 4
        obj.warn('Unable to calculate match score without descriptors.');
      end
      
      if nargout == 2
        commonPart = 1;
        descriptorsA = [];
        descriptorsB = [];
      end
     
      krisDir = kristianEvalBenchmark.installDir;
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
      overlap_err_idx = round(obj.opts.overlapError*10);

      addpath(krisDir);
      rehash;
      [err, tmprepScore, tmpnumCorresp, matchScore, numMatches] ...
          = repeatability(ellAFile,ellBFile,tmpHFile,imageAPath,imageBPath,commonPart);
      rmpath(krisDir);

      repScore = tmprepScore(overlap_err_idx)./100;
      numCorresp = tmpnumCorresp(overlap_err_idx);
      delete(ellAFile);
      delete(ellBFile);
      delete(tmpHFile);
      
      obj.info('Repeatability: %g \t Num correspondences: %g',repScore,numCorresp);
      
      obj.info('Match score: %g \t Num matches: %g',matchScore,numMatches);
      
      timeElapsed = toc(startTime);
      obj.debug('Score between %d/%d frames comp. in %gs',...
        size(framesA,2),size(framesB,2),timeElapsed);
    end

  end
  
   methods (Static)
    function cleanDeps()
    end

    function deps = getDependencies()
      deps = {helpers.Installer(),benchmarks.helpers.Installer()};
    end
    
    function srclist = getMexSources()
      import benchmarks.*;
      path = kristianEvalBenchmark.installDir;
      srclist = {fullfile(path,'c_eoverlap.cxx')};
    end
    
    function [urls dstPaths] = getTarballsList()
      import benchmarks.*;
      urls = {kristianEvalBenchmark.url};
      dstPaths = {kristianEvalBenchmark.installDir};
    end
    
   end
end

