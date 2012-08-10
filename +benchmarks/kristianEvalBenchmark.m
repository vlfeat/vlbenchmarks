classdef kristianEvalTest < affineDetectors.genericTest
  %KRISTIANEVALTEST Kristians Mikolajczyk's affine detectors test
  %   Implements test interface for Kristian's testing script of affine
  %   covarinat image regions (frames).
  %
  %   Options:
  %
  %   OverlapError :: [0.4]
  %     Overlap error of the ellipses for which the repeatability is
  %     calculated
  %
  %   CalcMatches :: [true]
  %     Calculate matching score. For correct results, the frames storage
  %     must contain descriptors. See documentation of framesStorage
  
  properties
    km_opts             % Options of the km eval
    repeatibilityScore  % Calculated rep. score
    numOfCorresp        % Calculated num of corresp.
    matchScore          % Calculated matching score.
    numOfMatches        % Calculated number of matches.
    imagePaths          % Paths to stored images
  end
  
  % TODO recalc when parameters changes - define signature of test.
  
  methods
    function obj = kristianEvalTest(framesStorage, varargin)
      name = 'kristian_eval';
      %obj = obj@affineDetectors.genericTest(resultsStorage, name, varargin{:});
      obj = obj@affineDetectors.genericTest(framesStorage, name);
      
      obj.km_opts.OverlapError = 0.4;
      obj.km_opts.CalcMatches = true;
      if numel(varargin) > 0
        obj.km_opts = commonFns.vl_argparse(obj.km_opts,varargin{:});
      end
      
      % Index of a value from the test results corresponding to idx*10 overlap
      % error. Kristian eval. computes only overlap errors in step of 0.1
      overlapErr = obj.km_opts.OverlapError;
      overlap_err_idx = round(overlapErr*10);
      if (overlapErr*10 - overlap_err_idx) ~= 0
          warning(['KM benchmark supports only limited set of overlap errors. ',...
                   'The comparison would not be accurate.']);
      end
      
      krisDir = affineDetectors.helpers.getKristianDir();
      if(~exist(krisDir,'dir'))
        error('Kristian''s benchmark not found, cannot run\n');
      end
      
      if obj.km_opts.CalcMatches && ~framesStorage.opts.calcDescriptors
        error ('For match score test, descriptors need to be calculated.');
      end
      
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      obj.repeatibilityScore = zeros(numDetectors,numImages); 
      obj.repeatibilityScore(:,1)=1;
      obj.numOfCorresp = zeros(numDetectors,numImages);
      obj.matchScore = zeros(numDetectors,numImages); 
      obj.matchScore(:,1)=1;
      obj.numOfMatches = zeros(numDetectors,numImages);
    end
    
    function runTest(obj)
      numDetectors = obj.framesStorage.numDetectors();            
      obj.framesStorage.calcFrames();
      
      
      numImages = obj.framesStorage.numImages();
      detNames = obj.framesStorage.detectorsNames;
      
      obj.imagePaths = cell(1,numImages);
      for image_i = 1:numImages
        obj.imagePaths{image_i} = obj.framesStorage.dataset.getImagePath(image_i);
      end
      
      fprintf('Running kristian eval on %d detectors:\n',numDetectors);
      calcMatches = obj.km_opts.CalcMatches;
      repScore = obj.repeatibilityScore;
      numCorresp = obj.numOfCorresp;
      matchScore = obj.matchScore;
      numMatches = obj.numOfMatches;
      hasChanges = true(numDetectors,1);
      
      for iDetector = 1:numDetectors
        hasChanges(iDetector) = obj.frames_has_changed(iDetector);
      end
      
      parfor iDetector = 1:numDetectors
        fprintf('\nRunning kristians benchmark code for %s detector.\n',detNames{iDetector});
        if hasChanges(iDetector)
          %detFrames = frames{iDetector};
          %detDescs = descriptors{iDetector};
          if calcMatches
            %[repScore(iDetector,:), numCorresp(iDetector,:), matchScore(iDetector,:), numMatches(iDetector,:)] ...
            %        = affineDetectors.runKristianEval(detFrames,imagePaths,images,tfs, ...
            %                          overlapErr , detDescs);
            [repScore(iDetector,:), numCorresp(iDetector,:),... 
             matchScore(iDetector,:), numMatches(iDetector,:)] = obj.runKristianEval(iDetector);
          else
          %    [repScore(iDetector,:), numCorresp(iDetector,:)] = ...
          %        affineDetectors.runKristianEval(detFrames,imagePaths,...
          %                        images,tfs,overlapErr);
            [repScore(iDetector,:), numCorresp(iDetector,:)] = obj.runKristianEval(iDetector);
          end
        else 
          fprintf('\nThe frames have not changed.\n');
        end
      end
      
      obj.repeatibilityScore = repScore;
      obj.numOfCorresp = numCorresp;
      obj.matchScore = matchScore;
      obj.numOfMatches = numMatches;
      
      obj.det_signatures = obj.framesStorage.det_signatures;

      fprintf('\n------ Kristian evaluation completed ---------\n');
      
      obj.plotResults();
      obj.printResults();
      
    end
  
    function plotResults(obj)
          % ----------------- Plot the evaluation scores ---------------------------------
        obj.plotScores(31, 'KM_repeatability', obj.repeatibilityScore, ...
                   'KM Detector repeatibility vs. image index', ...
                   'Repeatibility. %', 2);
        obj.plotScores(32, 'KM_numCorrespond', obj.numOfCorresp, ...
                   'KM Detector num. of correspondences vs. image index', ...
                   '#correspondences', 2);
        if obj.km_opts.CalcMatches
          obj.plotScores(33, 'KM_matchScore', obj.matchScore, ...
                     'KM Detector matching score vs. image index', ...
                     'Matching score %', 2);
          obj.plotScores(34, 'KM_numMatches', obj.numOfMatches, ...
                     'KM Detector num of matches vs. image index', ...
                     '#correct matches', 2);
        end
    end
    
    function printResults(obj)
      % -------- Print out and save the scores --------------------
      fprintf('\nOutput of Kristians benchmark:\n');
      obj.printScores(obj.repeatibilityScore,'repScore.txt', 'KM repeatability scores');
      obj.printScores(obj.numOfCorresp,'corrNum.txt', 'KM num. of correspondences');
      if obj.km_opts.CalcMatches
        obj.printScores(obj.matchScore,'matchScore.txt', 'KM match scores');
        obj.printScores(obj.numOfMatches,'matchesNum.txt', 'KM num. of matches');
      end
    end
  end
  
  
   methods (Access=protected)
    function [repScores numOfCorresp matchScores numOfMatches] = runKristianEval(obj,iDetector)
      frames = obj.framesStorage.frames{iDetector};
      descriptors = obj.framesStorage.descriptors{iDetector};
      overlapErr = obj.km_opts.OverlapError;
      images = obj.framesStorage.images;
      imagePaths = obj.imagePaths;
      tfs = obj.framesStorage.tfs;
      numImages = numel(images);

      repScores = zeros(1,numel(frames)); repScores(1) = 100;
      numOfCorresp = zeros(1,numel(frames));
      matchScores = zeros(1,numel(frames)); matchScores(1) = 100;
      numOfMatches = zeros(1,numel(frames));
      
      frames_1 = frames{1};
      descriptors_1 = descriptors{1};
      imagePaths_1 = imagePaths{1};
      
      if nargout == 2
        commonPart = 1;
      elseif nargout == 4
        commonPart = 0;
      end
      
      parfor i = 2:numImages
        % [framesA,framesB,framesA_,framesB_, descrsA, descrsB] = ...
        %  helpers.cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i}, ...
        %                                    descrs{1}, descrs{i});
        
        fprintf('Running Kristians''s benchmark on Img#%02d/%02d\n',i,numImages);
        [repScores(i) numOfCorresp(i) matchScores(i) numOfMatches(i)] = ...
          affineDetectors.helpers.runRepeatability(frames_1,frames{i},...
          descriptors_1,descriptors{i},tfs{i},imagePaths_1,...
          imagePaths{i},commonPart,overlapErr);

      end
    end

  end
  
end

