classdef repeatabilityTest < affineDetectors.genericTest
  %REPEATABILITYTEST Calc repeatability score of aff. cov. detectors test.
  %   repeatabilityTest(resultsStorage,'OptionName',optionValue,...)
  %   constructs an object for calculating repeatability score. 
  %
  %   Score is calculated when method runTest is invoked.
  %
  %   Options:
  %
  %   OverlapError :: [0.4]
  %   Maximal overlap error of ellipses to be considered as
  %   correspondences.
  %
  
  properties
    rep_opts            % Local options of repeatabilityTest
    repeatibilityScore  % Calculated repeatability score
    numOfCorresp        % Number of correspondences 
  end
  
  methods
    function obj = repeatabilityTest(resultsStorage, varargin)
      name = 'repeatability';
      %obj = obj@affineDetectors.genericTest(resultsStorage, name, varargin{:});
      obj = obj@affineDetectors.genericTest(resultsStorage, name);
      
      obj.rep_opts.overlapError = 0.4;
      obj.rep_opts.showQualitative = false;
      if numel(varargin) > 0
        obj.rep_opts = commonFns.vl_argparse(obj.rep_opts,varargin{:});
      end
      
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      obj.repeatibilityScore = zeros(numDetectors,numImages); 
      obj.repeatibilityScore(:,1)=1;
      obj.numOfCorresp = zeros(numDetectors,numImages);
      
      
    end
    
    function runTest(obj)
      import affineDetectors.*;
      obj.framesStorage.calcFrames();
      
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      detNames = obj.framesStorage.detectorsNames;
      
      frames = obj.framesStorage.frames;
      images = obj.framesStorage.images;
      tfs = obj.framesStorage.tfs;
      
      fprintf('\nRunning repeatability test on %d detectors:\n',numDetectors);
      
      for iDetector = 1:numDetectors
        fprintf('\nEvaluating frames from %s detector\n\n',detNames{iDetector});
        if obj.frames_has_changed(iDetector)
          for i=2:numImages
            fprintf('\tEvaluating regions for image: %02d/%02d ...\n',i,numImages);
            [framesA,framesB,framesA_,framesB_] = ...
                helpers.cropFramesToOverlapRegion(frames{iDetector}{1},frames{iDetector}{i},...
                tfs{i},images{1},images{i});

            frameMatches = matchEllipses(framesB_, framesA);
            [bestMatches,matchIdxs] = ...
                obj.findOneToOneMatches(frameMatches,framesA,framesB_);
            numBestMatches = sum(bestMatches);
            obj.repeatibilityScore(iDetector,i) = ...
                numBestMatches / min(size(framesA,2), size(framesB,2));
            obj.numOfCorresp(iDetector,i) = numBestMatches;
            
            if obj.rep_opts.showQualitative
              if islogical(obj.rep_opts.showQualitative) || sum(ismember(i,obj.rep_opts.showQualitative))
                obj.framesStorage.plotFrames(framesA,framesB,framesA_,framesB_,...
                iDetector,i,matchIdxs);
              end
            end
          end
          obj.repeatibilityScore(iDetector,:) = obj.repeatibilityScore(iDetector,:) * 100;
        else
          fprintf('\tDetected regions has not changed since last evaluation.\n');
        end
      end

      fprintf('\n------ Repeatability test completed ---------\n');
      
      obj.det_signatures = obj.framesStorage.det_signatures;
      
      obj.plotResults();
      obj.printResults();

    end
    
    function plotResults(obj)
      datasetName = obj.framesStorage.dataset.datasetName;
      obj.plotScores(21,'detectorEval', obj.repeatibilityScore, ...
           ['Detector repeatibility vs. image index (',datasetName,')'], ...
            'Repeatibility. %', 2);
      obj.plotScores(22, 'numCorrespond', obj.numOfCorresp, ...
           ['Detector num. of correspondences vs. image index (',datasetName,')'], ...
           '#correspondences', 2);
    end
    
    function printResults(obj)
      obj.printScores(obj.repeatibilityScore,'scores.txt', 'repeatability scores');
      obj.printScores(obj.numOfCorresp,'numCorresp.txt', 'num. of correspondences');
    end
    
  end
  
  methods (Access=private)
    
    function [bestMatches,matchIdxs] = findOneToOneMatches(obj,ev,framesA,framesB)
      matches = zeros(3,0);
      overlapThresh = 1 - obj.rep_opts.overlapError;
      bestMatches = zeros(1, size(framesA, 2)) ;
      matchIdxs = [];

      for j=1:size(framesA,2)
        numNeighs = length(ev.scores{j}) ;
        if numNeighs > 0
          matches = [matches, ...
                    [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
        end
      end

      matches = matches(:,matches(3,:)>overlapThresh);

      % eliminate assigment by priority, i.e. sort the matches by the score
      [drop, perm] = sort(matches(3,:), 'descend');
      matches = matches(:, perm);
      % Create maps which frames has not been 'used' yet
      availA = true(1,size(framesA,2));
      availB = true(1,size(framesB,2));

      for idx = 1:size(matches,2)
        aIdx = matches(1,idx);
        bIdx = matches(2,idx);
        if(availA(aIdx) && availB(bIdx))
          bestMatches(aIdx) = 1;
          matchIdxs = [matchIdxs bIdx];
          availA(aIdx) = false;
          availB(bIdx) = false;
        end
      end
    end
  end
  
end

