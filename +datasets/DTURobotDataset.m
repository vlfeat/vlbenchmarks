classdef DTURobotDataset < datasets.GenericDataset & helpers.Logger...
    & helpers.GenericInstaller


  properties (SetAccess=private, GetAccess=public)
    Category = 'arc1'; % Dataset category
    DataDir; % Image location
    ImgExt; % Image extension
    % Number of different perturbation configurations within the category.
    NumPerturbationsConfigurations;
    % Number of images for each perturbation configuration.
    NumImagesPerPerturbation;
    ImageNames;
    ImageNamesLabel;
    Viewpoints;
    Lightings;
    ReconstructionsDir;
    CacheDir;
    CamerasPath;
    ImgWidth;
    ImgHeight;
    CodeDir;
  end

  properties (Constant)
    KeyPrefix = 'DTURobotDataset';
    % All dataset categories
    AllCategories = {'arc1', 'arc2', 'arc3', 'linear_path', ...
                     'lighting_x', 'lighting_y'};
    %=3mm
    StrLBoxPad=3e-3;
    %pixels
    BackProjThresh=5;
    %Margin for change in scale, corrected for distance to the secen, in orer for a correspondance to be accepted. A value of 2 corresponds to an octave.
    ScaleMargin=2;
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
      round([0: 180.8/10: 180.8]*10)/10,... % lighting_x
      round([0: 80.3/10: 80.3]*10)/10,... % lighting_y
    };

    CategoryViewpoints = {...
      [1:24 26:49], ...
      [65:94], ...
      [95:119], ...
      [51:64], ...
      [12 25 56 64], ...
      [12 25 56 64], ...
    };

    CategoryLightings = {...
      0, ...
      0, ...
      0, ...
      0, ...
      [20:30], ...
      [31:41], ...
    };

    NumScenes = 60;
    %Size of search cells in the structured light grid.
    CellRadius = 10;
    % Installation directory
    RootInstallDir = fullfile('data','datasets','DTURobot');
    % Root url for dataset tarballs
%   % URL for code (+ some data) tarballs
    CodeUrl = 'http://roboimagedata.imm.dtu.dk/code/RobotEvalCode.tar.gz';
%    DatasetUrl = 'http://roboimagedata.imm.dtu.dk/code/RobotEvalCode.tar.gz';
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
      if strcmp(obj.Category,'lighting_x') || strcmp(obj.Category,'lighting_y')
        obj.NumPerturbationsConfigurations = numel(obj.CategoryLightings{loc})
        obj.NumImagesPerPerturbation = obj.NumScenes * numel(obj.CategoryViewpoints{loc});
      else
        obj.NumPerturbationsConfigurations = numel(obj.CategoryViewpoints{loc});
        obj.NumImagesPerPerturbation = obj.NumScenes;
      end

      obj.checkInstall(varargin);
      obj.ImageNames = obj.CategoryImageLabels{loc};
      obj.ImageNamesLabel = obj.CategoryImageNames{loc};
      obj.Viewpoints = obj.CategoryViewpoints{loc};
      obj.Lightings = obj.CategoryLightings{loc};
      obj.ReconstructionsDir = fullfile(obj.RootInstallDir, 'reconstructions');
      obj.CamerasPath = fullfile(obj.RootInstallDir, 'cameras.mat');
      obj.CacheDir = fullfile(obj.RootInstallDir, 'cache');
      obj.CodeDir = fullfile(obj.RootInstallDir, 'code');
      obj.ImgWidth = 1600;
      obj.ImgHeight = 1200;

      addpath(obj.CodeDir)
    end

    function imgPath = getImagePath(obj, imgId)
      imgPath = fullfile(obj.DataDir, sprintf('scene%.3d/%.3d_%.2d.png', ...
          imgId.scene, imgId.viewpoint, imgId.lighting));
    end

    function imgId = getReferenceImageId(obj, confNo, imgNo)
      imgId.scene = imgNo;
      imgId.viewpoint = 25;
      imgId.lighting = 0;
    end

    function imgId = getImageId(obj, confNo, imgNo)
      if strcmp(obj.Category,'lighting_x') || strcmp(obj.Category,'lighting_y')
        imgId.viewpoint = obj.Viewpoints(mod(imgNo, numel(obj.Viewpoints))+1);
        imgId.lighting = obj.Lightings(confNo);
        imgId.scene = floor(imgNo/numel(obj.Viewpoints));
      else
        imgId.viewpoint = obj.Viewpoints(confNo);
        imgId.lighting = 0;
        imgId.scene = imgNo;
      end
    end

    function tfs = getTransformation(obj, imageAId, imageBId)
      Cams = GetCamPair(imageAId.viewpoint, imageBId.viewpoint);
      %TODO
    end

    function frameOverlaps = getFrameOverlaps(obj, imageAId, imageBId, framesA, framesB)
      % Get 3D reconstruction
      [Grid3D, Pts] = GenStrLightGrid(imageAId.viewpoint, ...
          obj.ReconstructionsDir, obj.ImgHeight, obj.ImgWidth, ...
          obj.CellRadius, imageAId.scene);
      CamPair = GetCamPair(imageAId.viewpoint, imageBId.viewpoint);

      N = size(framesA,2);
      neighs = cell(1,N);
      scores = cell(1,N);
      for f = 1:N
        frame_ref = framesA(:, f)';
        [neighs{f}, scores{f}] = obj.overlap(Grid3D, Pts, CamPair, frame_ref, framesB');
      end
      frameOverlaps.neighs = neighs;
      frameOverlaps.scores = scores;
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
        
        if(~isempty(idx))
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


  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      import datasets.*;
      error('Dataset not available at the moment.')
      installDir = DTURobotDataset.RootInstallDir;
      dstPaths = {fullfile(installDir)};
      urls = {DTURobotDataset.CodeUrl};
    end
  end
end
