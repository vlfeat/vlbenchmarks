classdef DTURobotDataset < datasets.GenericTransfDataset ...
    & helpers.Logger & helpers.GenericInstaller
% 
% Options:
%   cellRadius [10]
%     Size of search cells in the structured light grid.

  properties (SetAccess=private, GetAccess=public)
    Category = 'arc1'; % Dataset category
    Viewpoints;
    Lightings;
    ReconstructionsDir;
    CacheDir;
    CamerasPath;
    DataDir;
    NumLabels;
    Opts = struct('cellRadius', 10);
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

    ImgWidth = 1600;
    ImgHeight = 1200;

    NumScenes = 60;
    
    % Installation directory
    RootInstallDir = fullfile('data','datasets','DTURobot');
    % URL for dataset tarballs
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
      obj.NumLabels = numel(obj.ImageNames);
      if strfind(obj.Category,'lighting')
        obj.NumImages = obj.NumScenes * obj.NumLabels * numel(obj.CategoryViewpoints{loc});
      else
        obj.NumImages = obj.NumScenes * obj.NumLabels;
      end
    end

    function imgPath = getImagePath(obj, imgToken)
      if isstruct(imgToken)
        imgPath = fullfile(obj.DataDir, sprintf('scene%.3d/%.3d_%.2d.png', ...
            imgToken.scene, imgToken.viewpoint, imgToken.lighting));
      else
        obj.error('Invalid image token.');
%         labelNo = floor(imgToken/obj.NumImages)+1;
%         sceneNo = mod(imgToken,obj.NumImages)+1;
%         imgToken = obj.getImageId(labelNo, sceneNo);
%         imgPath = obj.getImagePath(imgToken);
      end
    end

    
    function [geometry] = getSceneGeometry(obj, imgAToken, imgBToken)
      % GETSCENEGEOMETRY
    
      % If only one input argument, it is meant against the reference
      % images
      if nargin == 2
        imgBToken = imgAToken;
        imgAToken = obj.getReferenceImageToken(imgAToken.scene);
      end
      
      % Generate the grid and camera pairs
      [geometry.grid3D, geometry.pts] = GenStrLightGrid(imgAToken.viewpoint, ...
          obj.ReconstructionsDir, obj.ImgHeight, obj.ImgWidth, ...
          obj.Opts.cellRadius, imgAToken.scene);
      geometry.camPair = GetCamPair(imgAToken.viewpoint, imgBToken.viewpoint);
      
      % Set the parameters used for grid generation
      geometry.imgHeight = obj.ImgHeight;
      geometry.imgWidth = obj.ImgWidth;
      geometry.cellRadius = obj.Opts.cellRadius;
    end
    
    function imgToken = getImageToken(obj, sceneNo, labelNo)
      if strfind(obj.Category,'lighting')
        imgToken.viewpoint = obj.Viewpoints(mod(sceneNo, numel(obj.Viewpoints))+1);
        imgToken.lighting = obj.Lightings(labelNo);
        imgToken.scene = floor(sceneNo/numel(obj.Viewpoints))+1;
      else
        imgToken.viewpoint = obj.Viewpoints(labelNo);
        imgToken.lighting = 0;
        imgToken.scene = sceneNo;
      end
    end
  end

  methods (Static)
    function imgToken = getReferenceImageToken(sceneNo)
      imgToken.scene = sceneNo;
      imgToken.viewpoint = 25;
      imgToken.lighting = 0;
    end
  end
  
  methods (Access = protected)
    function deps = getDependencies(obj)
      deps = {consistencyModels.DTURobotConsistencyModel()};
    end
    
    function [urls dstPaths] = getTarballsList(obj)
      installDir = obj.RootInstallDir;
      dstPaths = {fullfile(installDir), ...
                  fullfile(installDir)};
      urls = {obj.ReconstructionsUrl, ...
              obj.ScenesUrl};
    end
  end
end
