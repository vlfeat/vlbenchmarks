classdef HomographyConsistencyModel < consistencyModels.GenericConsistencyModel ...
  & helpers.Logger & helpers.GenericInstaller
%UNTITLED4 Summary of this class goes here
%   Detailed explanation goes here
%   OverlapError:: 0.4
%     Maximal overlap error of frames to be considered as
%     correspondences.
%
%   NormaliseFrames:: true
%     Normalise the frames to constant scale (defaults is true for
%     detector repeatability tests, see Mikolajczyk et. al 2005).
%
%   NormalisedScale:: 30
%     When frames scale normalisation applied, fixed scale to which it is
%     normalised to.
%
%   CropFrames:: true
%     Crop the frames out of overlapping regions (regions present in both
%     images).
%
%   Magnification:: 3
%     When frames are not normalised, this parameter is magnification
%     applied to the input frames. Usually is equal to magnification
%     factor used for descriptor calculation.
%
%   WarpMethod:: 'linearise'
%     Numerical method used for warping ellipses. Available mathods are
%     'standard' and 'linearise' for precise reproduction of IJCV2005 
%     benchmark results.
  
  properties
    Opts = struct(...
      'overlapError', 0.4,...
      'normaliseFrames', true,...
      'cropFrames', true,...
      'magnification', 3,...
      'warpMethod', 'linearise',...
      'normalisedScale', 30 ...
      );
  end
  
  methods
    function obj = HomographyConsistencyModel(varargin)
      varargin = obj.configureLogger('Homography CM',varargin);
      varargin = obj.checkInstall(varargin);
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end
    
    function [corresps consistency subsres] = findConsistentCorresps(obj, ...
        sceneGeometry, framesA, framesB)
      import consistencyModels.homography.*;
      subsres = struct(); corresps = []; consistency = [];
      
      if ~isstruct(sceneGeometry) || ...
         ~isfield(sceneGeometry,'homography') ||...
         ~isfield(sceneGeometry,'imageASize') ||...
         ~isfield(sceneGeometry,'imageBSize')
        obj.error('Invalid scene geometry. Use obj.setGeometry().');
      end
      
      normFrames = obj.Opts.normaliseFrames;
      overlapError = obj.Opts.overlapError;
      overlapThresh = 1 - overlapError;
      tf = sceneGeometry.homography;
      imageASize = sceneGeometry.imageASize;
      imageBSize = sceneGeometry.imageBSize;

      % convert frames from any supported format to unortiented
      % ellipses for uniformity
      ellipsesA = localFeatures.helpers.frameToEllipse(framesA) ;
      ellipsesB = localFeatures.helpers.frameToEllipse(framesB) ;

      % map frames from image A to image B and viceversa
      reprojEllipsesA = localFeatures.helpers.warpEllipse(tf, ellipsesA,...
        'Method',obj.Opts.warpMethod) ;
      reprojEllipsesB = localFeatures.helpers.warpEllipse(inv(tf), ellipsesB,...
        'Method',obj.Opts.warpMethod) ;

      % optionally remove frames that are not fully contained in
      % both images
      if obj.Opts.cropFrames
        % find frames fully visible in both images
        bboxA = [1 1 imageASize(2)+1 imageASize(1)+1] ;
        bboxB = [1 1 imageBSize(2)+1 imageBSize(1)+1] ;

        visibleEllipsesA = helpers.isEllipseInBBox(bboxA, ellipsesA ) & ...
          helpers.isEllipseInBBox(bboxB, reprojEllipsesA);

        visibleEllipsesB = helpers.isEllipseInBBox(bboxA, reprojEllipsesB) & ...
          helpers.isEllipseInBBox(bboxB, ellipsesB );

        % Crop frames outside overlap region
        ellipsesA = ellipsesA(:,visibleEllipsesA);
        reprojEllipsesA = reprojEllipsesA(:,visibleEllipsesA);
        ellipsesB = ellipsesB(:,visibleEllipsesB);
        reprojEllipsesB = reprojEllipsesB(:,visibleEllipsesB);
        if isempty(ellipsesA) || isempty(ellipsesB)
          return;
        end
        
        subsres.validFramesA = visibleEllipsesA;
        subsres.validFramesB = visibleEllipsesB;
      end
      
      subsres.ellipsesA = ellipsesA;
      subsres.ellipsesB = ellipsesB;
      subsres.reprojEllipsesA = reprojEllipsesA;
      subsres.reprojEllipsesB = reprojEllipsesB;

      if ~normFrames
        % When frames are not normalised, account the descriptor region
        magFactor = obj.Opts.magnification^2;
        ellipsesA = [ellipsesA(1:2,:); ellipsesA(3:5,:).*magFactor];
        reprojEllipsesB = [reprojEllipsesB(1:2,:); ...
          reprojEllipsesB(3:5,:).*magFactor];
      end

      % Find all frames overlaps (in one-to-n array)
      [ellipsesPairs ellipsesOverlaps] = fastEllipseOverlap(reprojEllipsesB, ellipsesA, ...
        'NormaliseFrames',normFrames,'MinAreaRatio',overlapThresh,...
        'NormalisedScale',obj.Opts.normalisedScale);
      
      % Remove frame pairs that have insufficient overlap
      isValid = ellipsesOverlaps > overlapThresh;
      corresps = ellipsesPairs(:,isValid);
      consistency = ellipsesOverlaps(:,isValid);
    end
    
    function signature = getSignature(obj)
      signature = [helpers.struct2str(obj.Opts)];
    end
  end
  
  methods (Static)
    function sceneGeometry = createSceneGeometry(homography, imageASize, imageBSize)
      sceneGeometry = struct(...
        'homography', homography,...
        'imageASize',imageASize,...
        'imageBSize',imageBSize ...
        );
    end
  end
  
  methods (Access = protected)
    function deps = getDependencies(obj)
      deps = {helpers.Installer(),helpers.VlFeatInstaller('0.9.14'),...
        benchmarks.helpers.DataMatcher};
    end
    
    function [srclist flags] = getMexSources(obj)
      path = fullfile('+consistencyModels','+homography','');
      srclist = {fullfile(path,'mexComputeEllipseOverlap.cpp')};
      flags = {'',''};
    end
  end
end

