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
      frames = obj.framesStorage.frames;
      
      descriptors = obj.framesStorage.descriptors;
      images = obj.framesStorage.images;
      tfs = obj.framesStorage.tfs;
      numImages = obj.framesStorage.numImages();
      detNames = obj.framesStorage.detectorsNames;
      
      imagePaths = cell(1,numImages);
      for image_i = 1:numImages
        imagePaths{image_i} = obj.framesStorage.dataset.getImagePath(image_i);
      end
      
      fprintf('Running kristian eval on %d detectors:\n',numDetectors);
      
      for iDetector = 1:numDetectors
        fprintf('\nRunning kristians benchmark code for %s detector.\n',detNames{iDetector});
        if obj.frames_has_changed(iDetector)
          detFrames = frames{iDetector};
          detDescs = descriptors{iDetector};
          if obj.km_opts.CalcMatches && ~isempty(detDescs)
            [obj.repeatibilityScore(iDetector,:), obj.numOfCorresp(iDetector,:),...
             obj.matchScore(iDetector,:), obj.numOfMatches(iDetector,:)] ...
                    = affineDetectors.runKristianEval(detFrames,imagePaths,images,tfs, ...
                                      obj.km_opts.OverlapError, detDescs);
          else
              [obj.repeatibilityScore(iDetector,:), ...
               obj.numOfCorresp(iDetector,:)] = ...
                  affineDetectors.runKristianEval(detFrames,imagePaths,...
                                  images,tfs, obj.km_opts.OverlapError);
          end
        else 
          fprintf('\nThe frames have not changed.\n');
        end

      end
      
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
  
end

