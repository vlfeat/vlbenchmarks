classdef DTURobotDataset < datasets.GenericCorrespondenceDataset ...
    & helpers.Logger & helpers.GenericInstaller


  properties (SetAccess=private, GetAccess=public)
    Category = 'arc1'; % Dataset category
    Viewpoints;
    Lightings;
    ReconstructionsDir;
    CacheDir;
    CamerasPath;
    CodeDir;
    DataDir;
  end

  properties (Constant)
    % All dataset categories
    AllCategories = {'arc1', 'arc2', 'arc3', 'linear_path', ...
                     'lighting_x', 'lighting_y'};
  end

  properties (Constant, Hidden)
    % Names of the image transformations in particular categories
    CategoryImageNames = {...
      'Arc 1, viewpoint angle',...
      'Arc 2, viewpoint angle',...
      'Arc 3, viewpoint angle',...
      'Linear path, camera distance',...
      'Lighting changes, x coordinate',...
      'Lighting changes, y coordinate',...
      };
    % Image labels for particular categories (degree of transf.)
    CategoryImageLabels = {...
      round([[-40: 40/24: -1.6666666] [1.666666: 40/24: 40]]*10)/10,... % arc1
      round([-25: 50/29: 25]*10)/10,... % arc2
      round([-20: 40/24: 20]*10)/10,... % arc3
      round([.5214: .3/14: .8]*10)/10,...   % linear_path
      round([0: 180.8/8: 180.8]*10)/10,... % lighting_x
      round([0: 80.3/6: 80.3]*10)/10,... % lighting_y
    };
    % Viewpoint indices for each category.
    CategoryViewpoints = {...
      [1:24 26:49], ...
      [65:94], ...
      [95:119], ...
      [51:64], ...
      [12 25 60 87], ...
      [12 25 60 87], ...
    };
    % Lighting indices for each category.
    CategoryLightings = {...
      0, ...
      0, ...
      0, ...
      0, ...
      [20:28], ...
      [29:35], ...
    };
    % Size of search cells in the structured light grid.
    CellRadius = 10;
    % Acceptance threshold of point distance in 3D. 3e-3 = 3mm.
    StrLBoxPad=3e-3;
    % Acceptance threshold of backprojection error in pixels.
    BackProjThresh=5;
    % Acceptance threshold of scale difference after distance normalization. A 
    % value of 2 corresponds to an octave.
    ScaleMargin = 2;

    ImgWidth = 1600;
    ImgHeight = 1200;

    % Installation directory
    RootInstallDir = fullfile('data','datasets','DTURobot');
    % URL for dataset tarballs
    CodeUrl = 'http://roboimagedata.imm.dtu.dk/data/code.tar.gz';
    ReconstructionsUrl = 'http://roboimagedata.imm.dtu.dk/data/ground_truth.tar.gz';
    ScenesUrl = 'http://roboimagedata.imm.dtu.dk/data/condensed.tar.gz';
  end

  methods
    function obj = DTURobotDataset(varargin)
      import datasets.*;
      import helpers.*;
      opts.Category = obj.Category;
      [opts varargin] = vl_argparse(opts,varargin);
      [valid loc] = ismember(opts.Category,obj.AllCategories);
      assert(valid,...
        sprintf('Invalid category for DTURobot dataset: %s\n',opts.Category));
      obj.DatasetName = ['DTURobotDataset-' opts.Category];
      obj.Category= opts.Category;
      obj.DataDir = fullfile(obj.RootInstallDir,'scenes');

      obj.checkInstall(varargin);
      obj.ImageNames = obj.CategoryImageLabels{loc};
      obj.ImageNamesLabel = obj.CategoryImageNames{loc};
      obj.Viewpoints = obj.CategoryViewpoints{loc};
      obj.Lightings = obj.CategoryLightings{loc};
      obj.ReconstructionsDir = fullfile(obj.RootInstallDir, 'reconstructions');
      obj.CamerasPath = fullfile(obj.RootInstallDir, 'cameras.mat');
      obj.CacheDir = fullfile(obj.RootInstallDir, 'cache');
      obj.CodeDir = fullfile(obj.RootInstallDir, 'code');
      obj.NumScenes = 60;
      obj.NumLabels = numel(obj.ImageNames);
      if strfind(obj.Category,'lighting')
        obj.NumImages = obj.NumScenes * obj.NumLabels * numel(obj.CategoryViewpoints{loc});
      else
        obj.NumImages = obj.NumScenes * obj.NumLabels;
      end
      addpath(obj.CodeDir)
    end

    function imgPath = getImagePath(obj, imgId)
      if isstruct(imgId)
        imgPath = fullfile(obj.DataDir, sprintf('scene%.3d/%.3d_%.2d.png', ...
            imgId.scene, imgId.viewpoint, imgId.lighting));
      else
        labelNo = floor(imgId/obj.NumImages)+1;
        sceneNo = mod(imgId,obj.NumImages)+1;
        imgId = obj.getImageId(labelNo, sceneNo);
        imgPath = obj.getImagePath(imgId);
      end
    end

    function imgId = getReferenceImageId(obj, labelNo, sceneNo)
      imgId.scene = sceneNo;
      imgId.viewpoint = 25;
      imgId.lighting = 0;
    end

    function imgId = getImageId(obj, labelNo, sceneNo)
      if strfind(obj.Category,'lighting')
        imgId.viewpoint = obj.Viewpoints(mod(sceneNo, numel(obj.Viewpoints))+1);
        imgId.lighting = obj.Lightings(labelNo);
        imgId.scene = floor(sceneNo/numel(obj.Viewpoints))+1;
      else
        imgId.viewpoint = obj.Viewpoints(labelNo);
        imgId.lighting = 0;
        imgId.scene = sceneNo;
      end
    end

    function [validFramesA validFramesB] = validateFrames(obj, ...
        imgAId, imgBId, framesA, framesB)
        validFramesA = logical(ones(1, size(framesA,2)));
        validFramesB = logical(ones(1, size(framesB,2)));
    end

    function overlaps = scoreFrameOverlaps(obj, imgAId, imgBId, framesA, framesB)
      % Get 3D reconstruction
      [Grid3D, Pts] = GenStrLightGrid(imgAId.viewpoint, ...
          obj.ReconstructionsDir, obj.ImgHeight, obj.ImgWidth, ...
          obj.CellRadius, imgAId.scene);
      CamPair = GetCamPair(imgAId.viewpoint, imgBId.viewpoint);

      N = size(framesA,2);
      neighs = cell(1,N);
      scores = cell(1,N);
      for f = 1:N
        frame_ref = framesA(:, f)';
        [neighs{f}, scores{f}] = obj.overlap(Grid3D, Pts, CamPair, frame_ref, framesB');
      end
      overlaps.neighs = neighs;
      overlaps.scores = scores;
    end


    function [neighs, scores] = overlap(obj, Grid3D, Pts, Cams, frame_ref, frames)
      KeyP = frame_ref(1:2);
      KeyScale = frame_ref(3);

      % Project point onto 3D structure 
      [Mean,Var,IsEst] = Get3DGridEst(Grid3D,Pts,obj.CellRadius,KeyP(1),KeyP(2));

      neighs = [];
      scores = [];
      if(IsEst)
        Var = Var+obj.StrLBoxPad;
        Q = Mean*ones(1,8)+[Var(1)*[-1  1 -1  1 -1  1 -1  1];
                            Var(2)*[-1 -1  1  1 -1 -1  1  1];
                            Var(3)*[-1 -1 -1 -1  1  1  1  1]];
        q = Cams(:,:,2)*[Q;ones(1,8)];
        depth = mean(q(3,:));
        q(1,:) = q(1,:)./q(3,:);
        q(2,:) = q(2,:)./q(3,:);
        q(3,:) = q(3,:)./q(3,:);
        
        kq = Cams(:,:,1)*[Q;ones(1,8)];
        kDepth = mean(kq(3,:));
        Scale = KeyScale*kDepth/depth;
        
        % Find neighbor frames within scale bounds
        idx = find(frames(:,1)>min(q(1,:)) & frames(:,1)<max(q(1,:)) & ...
                   frames(:,2)>min(q(2,:)) & frames(:,2)<max(q(2,:)) & ...
                   frames(:,3)>Scale/obj.ScaleMargin & ...
                   frames(:,3)<Scale*obj.ScaleMargin );
        
        for i=1:length(idx),
          % Score matches 
          consistency = PointCamGeoConsistency([KeyP 1]', [frames(idx(i),1:2) 1]', Cams);
          if consistency < obj.BackProjThresh
            neighs = [neighs idx(i)];
            scores = [scores 1/consistency];
          end
        end
      end
    end


  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      import datasets.*;
      installDir = DTURobotDataset.RootInstallDir;
      dstPaths = {fullfile(installDir),
                  fullfile(installDir),
                  fullfile(installDir)};
      urls = {DTURobotDataset.CodeUrl,
              DTURobotDataset.ReconstructionsUrl,
              DTURobotDataset.ScenesUrl};
    end
  end
end
