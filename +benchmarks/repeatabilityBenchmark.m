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
  %   ShowQualitative :: []
  %   Show the detected and matched frames on images with defined ids.
  %
  %   NormaliseFrames :: [true]
  %   Normalise the frames to constant scale (defaults is true for detector
  %   repeatability tests, see Mikolajczyk et. al 2005).
  %
  
  properties
    rep_opts            % Local options of repeatabilityTest
    repeatibilityScore  % Calculated repeatability score
    numOfCorresp        % Number of correspondences 
    reprojectedFrames;  % Cropped and reprojected frames
  end
  
  methods
    function obj = repeatabilityTest(resultsStorage, varargin)
      name = 'repeatability';
      %obj = obj@affineDetectors.genericTest(resultsStorage, name, varargin{:});
      obj = obj@affineDetectors.genericTest(resultsStorage, name);
      
      obj.rep_opts.overlapError = 0.4;
      obj.rep_opts.normaliseFrames = true;
      obj.rep_opts.showQualitative = [];
      if numel(varargin) > 0
        obj.rep_opts = commonFns.vl_argparse(obj.rep_opts,varargin{:});
      end
      
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      obj.repeatibilityScore = zeros(numDetectors,numImages); 
      obj.repeatibilityScore(:,1)=1;
      obj.numOfCorresp = zeros(numDetectors,numImages);
      
      obj.reprojectedFrames = cell(numDetectors,numImages);
      
    end
    
    function runTest(obj)
      import affineDetectors.*;
      storage = obj.framesStorage;
      storage.calcFrames();
      
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      detNames = obj.framesStorage.detectorsNames;
      
      frames = obj.framesStorage.frames;
      images = obj.framesStorage.images;
      tfs = obj.framesStorage.tfs;
      image_1 = images{1};
      
      showQualitative = obj.rep_opts.showQualitative;
      
      fprintf('\nRunning repeatability test on %d detectors:\n',numDetectors);
      
      % TODO export this outer for loop into generic test
      for iDetector = 1:numDetectors
        fprintf('\nEvaluating frames from %s detector\n\n',detNames{iDetector});
        if obj.frames_has_changed(iDetector)
          norm_frames = obj.rep_opts.normaliseFrames;
          overlap_err = obj.rep_opts.overlapError;
          repScore = obj.repeatibilityScore(iDetector,:);
          numCorresp = obj.numOfCorresp(iDetector,:);
          detFrames_1 = frames{iDetector}{1};
          detFrames = frames{iDetector};
          repFrames = obj.reprojectedFrames{iDetector};
          parfor i=2:numImages
            fprintf('\tEvaluating regions for image: %02d/%02d ...\n',i,numImages);
            [framesA,framesB,framesA_,framesB_] = ...
                helpers.cropFramesToOverlapRegion(detFrames_1,detFrames{i},...
                tfs{i},image_1,images{i});

            frameMatches = matchEllipses(framesB_, framesA,... 
              'NormaliseFrames',norm_frames);
            bestMatches = ...
                helpers.findOneToOneMatches(frameMatches,framesA,framesB_,overlap_err);
            numBestMatches = sum(bestMatches ~= 0);
            repScore(i) = numBestMatches / min(size(framesA,2), size(framesB,2));
            numCorresp(i) = numBestMatches;
            
            if sum(ismember(i,showQualitative))
              % TODO write this more effectively at all... (remove frames
              % from the list just by indexing, not creating new list)
              repFrames{i} = {framesA framesA_; framesB framesB_; bestMatches []};
            end
          end
          obj.reprojectedFrames{iDetector} = repFrames;
          obj.repeatibilityScore(iDetector,:) = repScore(1,:) * 100;
          obj.numOfCorresp(iDetector,:) = numCorresp(1,:);
        else
          fprintf('\tDetected regions has not changed since last evaluation.\n');
        end
      end

      fprintf('\n------ Repeatability test completed ---------\n');
      
      obj.det_signatures = obj.framesStorage.det_signatures;
      
      obj.showQualitativeResults();
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
    
    function showQualitativeResults(obj)
      numDetectors = obj.framesStorage.numDetectors();
      numImages = obj.framesStorage.numImages();
      showQualitative = obj.rep_opts.showQualitative;
      for iDetector = 1:numDetectors
        for i=2:numImages
          if sum(ismember(i,showQualitative))
            figure(iImg);
            obj.plotReprojectedFrames(iDetector,i);
          end
        end
      end
    end
    
    function plotReprojectedFrames(obj,iDetector,iImg)
      % TODO fix it with the new arguments
      numDetectors = obj.framesStorage.numDetectors();
      detectorName = obj.detectors{iDetector}.detectorName;
      imageA = obj.framesStorage.images{1};
      imageB = obj.framesStorage.images{iImg};
      subplot(numDetectors,2,2*(iDetector-1)+1) ; imshow(imageA);
      colormap gray ;
      hold on ; vl_plotframe(framesA,'linewidth', 1);
      % Plot the transformed and matched frames from B on A in blue
      matchLogical = false(1,size(framesB_,2));
      matchLogical(matchIdxs) = true;
      vl_plotframe(framesB_(:,matchLogical),'b','linewidth',1);
      % Plot the remaining frames from B on A in red
      vl_plotframe(framesB_(:,~matchLogical),'r','linewidth',1);
      axis equal;
      set(gca,'xtick',[],'ytick',[]);
      ylabel(detectorName);
      title('Reference image detections');

      subplot(numDetectors,2,2*(iDetector-1)+2) ; imshow(imageB) ;
      hold on ; vl_plotframe(framesB,'linewidth', 1) ;axis equal; axis off;
      %vl_plotframe(framesA_, 'b', 'linewidth', 1) ;
      title('Transformed image detections');

      drawnow;
    end
    
  end
  
end

