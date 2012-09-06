% VGGAFFINEDATASET class to wrap around the vgg affine datasets
%
%   The dataset is available at: http://www.robots.ox.ac.uk/~vgg/research/affine/
%

%   obj = vggAffineDataset('Option','OptionValue')
%
%   This class perform automatic installation when the dataset data are
%   not available.
%
%   Following options are supported:
%
%   Category :: ['graf']
%     The category within the vgg dataset, has to be one of 'bikes','trees',
%     'graf','wall','bark','boat','leuven','ubc'

classdef vggAffineDataset < datasets.genericTransfDataset & helpers.Logger...
    & helpers.GenericInstaller
  properties (SetAccess=private, GetAccess=public)
    category
    dataDir
    imgExt
  end

  properties (Constant)
    rootInstallDir = fullfile('data','datasets','vggAffineDataset','');
    allCategories = {'graf','wall','boat','bark','bikes','trees',...
      'ubc','leuven'};
    categoryImageNames = {...
      'Viewpoint angle',... % graf
      'Viewpoint angle',... % wall
      'Scale changes',... % boat
      'Scale changes',... % bark
      'Increasing blur',... % bikes
      'Increasing blur',... % trees
      'JPEG compression %',... % ubc
      'Decreasing light'...% leuven
      };
    categoryImageLabels = {...
      [20 30 40 50 60],... % graf
      [20 30 40 50 60],... % wall
      [1.12 1.38 1.9 2.35 2.8],... % boat
      [0.3 1.8 2.5 3 4],...   % bark
      [2 3 4 5 6],... % bikes
      [2 3 4 5 6],... % trees
      [60 80 90 95 98],... % ubc
      [2 3 4 5 6]...% leuven
      };
    rootUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/';
    defCategory = 'graf';
  end

  
  methods
    function obj = vggAffineDataset(varargin)
      import datasets.*;
      import helpers.*;
      if ~obj.isInstalled(),
        obj.warn('Vgg Affine dataset is not installed');
        obj.installDeps();
      end
      opts.category= obj.defCategory;
      opts = vl_argparse(opts,varargin);
      [valid loc] = ismember(opts.category,obj.allCategories);
      assert(valid,...
        sprintf('Invalid category for vgg dataset: %s\n',opts.category));
      obj.datasetName = ['vggAffineDataset-' opts.category];
      obj.category= opts.category;
      obj.dataDir = fullfile(obj.rootInstallDir,opts.category,'');
      obj.numImages = 6;
      ppm_files = dir(fullfile(obj.dataDir,'img*.ppm'));
      pgm_files = dir(fullfile(obj.dataDir,'img*.pgm'));
      if size(ppm_files,1) == 6
        obj.imgExt = 'ppm';
      elseif size(pgm_files,1) == 6
        obj.imgExt = 'pgm';
      else
        error('Ivalid dataset image files.');
      end
      obj.imageNames = obj.categoryImageLabels{loc};
      obj.imageNamesLabel = obj.categoryImageNames{loc};
    end

    function imgPath = getImagePath(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.numImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.dataDir,sprintf('img%d.%s',imgIdx,obj.imgExt));
    end

    function tfs = getTransformation(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.numImages,'Out of bounds idx\n');
      if(imgIdx == 1), tfs = eye(3); return; end
      tfs = zeros(3,3);
      [tfs(:,1) tfs(:,2) tfs(:,3)] = ...
         textread(fullfile(obj.dataDir,sprintf('H1to%dp',imgIdx)),...
         '%f %f %f%*[^\n]');
    end

  end

  methods (Static)
    
    function [urls dstPaths] = getTarballsList()
      import datasets.*;
      numCategories = numel(vggAffineDataset.allCategories);
      urls = cell(1,numCategories);
      dstPaths = cell(1,numCategories);
      installDir = vggAffineDataset.rootInstallDir;
      for i = 1:numCategories
        curCategory = vggAffineDataset.allCategories{i};
        dstPaths{i} = fullfile(installDir,curCategory);
        urls{i} = [vggAffineDataset.rootUrl curCategory '.tar.gz'];
      end
    end

  end % --- end of static methods ---

end % -------- end of class ---------
