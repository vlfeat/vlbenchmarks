classdef kristianEvalBenchmark < benchmarks.genericBenchmark
  %KRISTIANEVALBENCHMARK Kristians Mikolajczyk's affine detectors test
  %   Implements test interface for Kristian's testing script of affine
  %   covarinat image regions (frames).
  %
  %   Options:
  %
  %   OverlapError :: [0.4]
  %     Overlap error of the ellipses for which the repeatability is
  %     calculated. Can be only in {0.1, 0.2, ... ,0.9}.
  %
  
  properties
    opts                % Options of the km eval
  end
  
  properties (Constant)
    defOverlapError = 0.4;
    repeatabilityDir = fullfile('data','software','repeatability','');
    keyPrefix = 'kmEval_';
    testTypeKeys = {'rep','rep+match'};
  end
  
  methods
    function obj = kristianEvalBenchmark(varargin)
      name = 'kristian_eval';
      obj = obj@benchmarks.genericBenchmark(name);
      
      obj.opts.OverlapError = kristianEvalBenchmark.defOverlapError;
      if numel(varargin) > 0
        obj.opts = commonFns.vl_argparse(obj.opts,varargin{:});
      end
      
      % Index of a value from the test results corresponding to idx*10 overlap
      % error. Kristian eval. computes only overlap errors in step of 0.1
      overlapErr = obj.opts.OverlapError;
      overlapErrIdx = round(overlapErr*10);
      if (overlapErr*10 - overlapErrIdx) ~= 0
          warning(['KM benchmark supports only limited set of overlap errors. ',...
                   'Your overlap error was rounded.']);
      end
      
      if(~kristianEvalBenchmark.isInstalled())
        disp('Kristian''s benchmark not found, installing dependencies...');
        kristianEvalBenchmark.installDeps();
      end      
    end
    
    function [repeatability, numCorresp, matchScore, numMatches] = ...
                testDetector(obj, detector, tf, imageAPath, imageBPath)
      fprintf('Running kristian eval.');
      
      imageASign = helpers.fileSignature(imageAPath);
      imageBSign = helpers.fileSignature(imageAPath);
      detSign = detector.getSignature();
      testType = kristianEvalBenchmark.testTypeKeys{nargout/2};
      keyPrefix = kristianEvalBenchmark.keyPrefix;
      resultsKey = strcat(keyPrefix,testType,detSign,imageASign,imageBSign);
      cachedResults = DataCache.getData(resultsKey);
      
      if isempty(cachedResults)
        if nargout == 4
          [framesA descriptorsA] = detector.extractFeatures(imageAPath);
          [framesB descriptorsB] = detector.extractFeatures(imageBPath);
          [repeatability, numCorresp, matchScore, numMatches] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, ...
                             framesA, framesB, descriptorsA, descriptorsB);
        else
          [framesA] = detector.extractFeatures(imageAPath);
          [framesB] = detector.extractFeatures(imageBPath);
          [repeatability, numCorresp] = ...
            obj.testFeatures(tf, imageAPath, imageBPath, framesA, framesB);
          matchScore = -1;
          numMatches = -1;
        end
        
        results = {repeatability numCorresp matchScore numMatches};
        DataCache.storeData(results, resultsKey);
      else
        [repeatability numCorresp matchScore numMatches] = cachedResults{:};
      end
      
    end

    function [repeatability numCorresp matchScore numMatches] = ... 
                testFeatures(obj, tf, imageAPath, imageBPath, ...
                             framesA, framesB, descriptorsA, descriptorsB)
      
      if nargout == 4 && nargin == 8
        commonPart = 1;
      elseif nargout == 4
        warning('Unable to calculate match score without descriptors.');
      end
      
      if nargout == 2
        commonPart = 0;
        descriptorsA = [];
        descriptorsB = [];
      end
     
      krisDir = kristianEvalBenchmark.repeatabilityDir;
      tmpFile = tempname;
      ellBFile = [tmpFile 'ellB.txt'];
      tmpHFile = [tmpFile 'H.txt'];
      ellAFile = [tmpFile 'ellA.txt'];
      helpers.vggwriteell(ellAFile,frameToEllipse(framesA), descriptorsA);
      helpers.vggwriteell(ellBFile,frameToEllipse(framesB), descriptorsB);
      H = tf;
      save(tmpHFile,'H','-ASCII');
      overlap_err_idx = round(obj.opts.overlapError*10);

      addpath(krisDir);
      rehash;
      [err, tmprepeatability, tmpnumCorresp, matchScore, numMatches] ...
          = repeatability(ellAFile,ellBFile,tmpHFile,imageAPath,imageBPath,commonPart);
      rmpath(krisDir);

      repeatability = tmprepeatability(overlap_err_idx);
      numCorresp = tmpnumCorresp(overlap_err_idx);
      delete(ellAFile);
      delete(ellBFile);
      delete(tmpHFile);
    end

  end
  
   methods (Static)
    function cleanDeps()
    end

    function installDeps()
    end

    function result = isInstalled()
      repeatabilityFile = fullfile(kristianEvalBenchmark.repeatabilityDir,'repeatability.m');
      result = exist(repeatabilityFile,'file');
    end
   end
end

