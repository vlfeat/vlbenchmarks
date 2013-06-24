classdef DTURobotConsistencyModel < consistencyModels.GenericConsistencyModel ...
    & helpers.GenericInstaller & helpers.Logger
 
% DTURobotConsistencyModel
% 
% Options:
%   strLBoxPad [3e-3]
%     Acceptance threshold of point distance in 3D. 3e-3 = 3mm.
%
%   backProjThresh [5]
%     Acceptance threshold of backprojection error in pixels.
%
%   scaleMargin [2]
%     Acceptance threshold of scale difference after distance
%     normalization. A value of 2 corresponds to an octave.
  
% Authors: Anders Boesen Lindbo Larsen, Karel Lenc

% AUTORIGHTS

  properties (SetAccess = protected, GetAccess = public)
    Opts = struct(...
      'strLBoxPad', 3e-3, ...
      'backProjThresh', 5, ...
      'scaleMargin', 2 ...
      );
  end

  properties (Constant, Hidden)
    % Installation directory - so far must be in the same directory as the
    % dataset - it loads the camera file based on the m file location.
    RootInstallDir = fullfile('data','datasets','DTURobot');
    % Code directory
    CodeDir = fullfile(consistencyModels.DTURobotConsistencyModel.RootInstallDir, 'code');
    % URL for dataset tarballs
    CodeUrl = 'http://roboimagedata.imm.dtu.dk/data/code.tar.gz';
  end
  
  methods
    
    function obj = DTURobotConsistencyModel(varargin)
      varargin = obj.configureLogger('DTU Robot CM',varargin);
      varargin = obj.checkInstall(varargin);
      obj.Opts = vl_argparse(obj.Opts,varargin);
    end
    
    function [corresps consistency subsres] = findConsistentCorresps(obj, ...
      sceneGeometry, framesA, framesB)

      % Convert frames to similarity invariant frames
      framesAScale = localFeatures.helpers.getFrameScale(framesA);
      framesA = [framesA(1:2,:); framesAScale];
      framesBScale = localFeatures.helpers.getFrameScale(framesB);
      framesB = [framesB(1:2,:); framesBScale];
    
      N = size(framesA,2);
      corresps = cell(1,N);
      consistency = cell(1,N);
      reconsRefFrames = cell(1,N);
      for f = 1:N
        frame_ref = framesA(:, f)';
        [corresps{f}, consistency{f} reconsRefFrames{f}] = ...
          obj.overlap(sceneGeometry, frame_ref, framesB');
        corresps{f} = [repmat(f, 1, numel(corresps{f}));corresps{f}];
      end
      
      hasCorresp = ~cellfun(@isempty,corresps);
      corresps = corresps(hasCorresp);
      consistency = consistency(hasCorresp);
      
      corresps = cell2mat(corresps);
      consistency = cell2mat(consistency);
      reconsRefFrames = cell2mat(reconsRefFrames);
      subsres.reconstructedRefFrames = reconsRefFrames;
    end
    
    function setup(obj)
      addpath(obj.CodeDir);
    end
    
    function unload(obj)
      rmpath(obj.CodeDir);
    end
    
    function signature = getSignature(obj)
      signature = [helpers.struct2str(obj.Opts)];
    end
    
  end
  
  methods (Access = protected)
    function [corresps, scores, subsres] = overlap(obj, sceneGeometry, frame_ref, frames)
      subsres = struct('gridPtMean',[],'gridPtVar',[],'bbox',[],'scale',[]);
      KeyP = frame_ref(1:2);
      KeyScale = frame_ref(3);
      
      grid3D = sceneGeometry.grid3D;
      pts = sceneGeometry.pts;
      cams  = sceneGeometry.camPair;
      cellRadius = sceneGeometry.cellRadius;
      % Shortcuts for the options
      scaleMargin = obj.Opts.scaleMargin;
      backProjThresh = obj.Opts.backProjThresh;
      strLBoxPad = obj.Opts.strLBoxPad;

      % Project point onto 3D structure 
      [Mean,Var,IsEst] = Get3DGridEst(grid3D,pts,cellRadius,KeyP(1),KeyP(2));

      corresps = [];
      scores = [];
      if(IsEst)
        subsres.gridPtMean = Mean;
        subsres.gridPtVar = Var;
        Var = Var + strLBoxPad;
        % 3D points of the bounding cube
        Q = Mean*ones(1,8)+[Var(1)*[-1  1 -1  1 -1  1 -1  1];
                            Var(2)*[-1 -1  1  1 -1 -1  1  1];
                            Var(3)*[-1 -1 -1 -1  1  1  1  1]];
        % Reproject to the tested image
        q = cams(:,:,2)*[Q;ones(1,8)];
        depth = mean(q(3,:));
        q(1,:) = q(1,:)./q(3,:);
        q(2,:) = q(2,:)./q(3,:);
        q(3,:) = q(3,:)./q(3,:);
        bbox = [min(q(1,:)) max(q(1,:)) min(q(2,:)) max(q(2,:))] ;
        subsres.bbox = bbox;
        
        % Reproject the bounding cube to the reference image
        kq = cams(:,:,1)*[Q;ones(1,8)];
        kDepth = mean(kq(3,:));
        Scale = KeyScale*kDepth/depth;
        subsres.scale = Scale;
        
        % Find neighbor frames within scale bounds
        idx = find(frames(:,1)>bbox(1) & frames(:,1)<bbox(2) & ...
                   frames(:,2)>bbox(3) & frames(:,2)<bbox(4) & ...
                   frames(:,3)>Scale/scaleMargin & ...
                   frames(:,3)<Scale*scaleMargin );
        
        consistency = zeros(1,numel(idx));
        for i=1:length(idx)
          % Score matches 
          consistency(i) = PointCamGeoConsistency([KeyP 1]', [frames(idx(i),1:2) 1]', cams);
        end
        
        isValidConsistency = consistency < backProjThresh;
        corresps = idx(isValidConsistency)';
        scores = 1./consistency(isValidConsistency);
      end
    end
    
    function [urls dstPaths] = getTarballsList(obj)
      installDir = obj.RootInstallDir;
      dstPaths = {fullfile(installDir)};
      urls = {obj.CodeUrl};
    end
  end
end

