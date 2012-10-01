classdef VggAffineDataset < datasets.GenericTransfDataset & helpers.Logger...
    & helpers.GenericInstaller
% datasets.VggAffineDataset Wrapper around the vgg affine datasets
%   datasets.VggAffineDataset('Option','OptionValue',...) Constructs
%   an object which implements access to VGG Affine dataset used for
%   affine invariant detectors evaluation.
%
%   The dataset is available at: 
%   http://www.robots.ox.ac.uk/~vgg/research/affine/
%
%   This class perform automatic installation when the dataset data
%   are not available.
%
%   Following options are supported:
%
%   Category :: ['graf']
%     The category within the VGG dataset, has to be one of
%     'bikes', 'trees', 'graf', 'wall', 'bark', 'boat', 'leuven', 'ubc'

% Authors: Varun Gulshan, Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Category = 'graf'; % Dataset category
    DataDir; % Image location
    ImgExt; % Image extension
  end

  properties (Constant)
    % All dataset categories
    AllCategories = {'graf','wall','boat','bark','bikes','trees',...
      'ubc','leuven'};
  end

  properties (Constant, Hidden)
    % Installation directory
    RootInstallDir = fullfile('data','datasets','vggAffineDataset','');
    % Names of the image transformations in particular categories
    CategoryImageNames = {...
      'Viewpoint angle',... % graf
      'Viewpoint angle',... % wall
      'Scale changes',... % boat
      'Scale changes',... % bark
      'Increasing blur',... % bikes
      'Increasing blur',... % trees
      'JPEG compression %',... % ubc
      'Decreasing light'...% leuven
      };
    % Image labels for particular categories (degree of transf.)
    CategoryImageLabels = {...
      [20 30 40 50 60],... % graf
      [20 30 40 50 60],... % wall
      [1.12 1.38 1.9 2.35 2.8],... % boat
      [1.2 1.8 2.5 3 4],...   % bark
      [2 3 4 5 6],... % bikes
      [2 3 4 5 6],... % trees
      [60 80 90 95 98],... % ubc
      [2 3 4 5 6]...% leuven
      };
    % Root url for dataset tarballs
    RootUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/';
  end

  methods
    function obj = VggAffineDataset(varargin)
      import datasets.*;
      import helpers.*;
      opts.Category = obj.Category;
      [opts varargin] = vl_argparse(opts,varargin);
      [valid loc] = ismember(opts.Category,obj.AllCategories);
      assert(valid,...
        sprintf('Invalid category for vgg dataset: %s\n',opts.Category));
      obj.DatasetName = ['VggAffineDataset-' opts.Category];
      obj.Category= opts.Category;
      obj.DataDir = fullfile(obj.RootInstallDir,opts.Category,'');
      obj.NumImages = 6;
      obj.checkInstall(varargin);
      ppm_files = dir(fullfile(obj.DataDir,'img*.ppm'));
      pgm_files = dir(fullfile(obj.DataDir,'img*.pgm'));
      if size(ppm_files,1) == 6
        obj.ImgExt = 'ppm';
      elseif size(pgm_files,1) == 6
        obj.ImgExt = 'pgm';
      else
        error('Ivalid dataset image files.');
      end
      obj.ImageNames = obj.CategoryImageLabels{loc};
      obj.ImageNamesLabel = obj.CategoryImageNames{loc};
    end

    function imgPath = getImagePath(obj,imgNo)
      assert(imgNo >= 1 && imgNo <= obj.NumImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.DataDir,sprintf('img%d.%s',imgNo,obj.ImgExt));
    end

    function tfs = getTransformation(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.NumImages,'Out of bounds idx\n');
      if(imgIdx == 1), tfs = eye(3); return; end
      tfs = zeros(3,3);
      [tfs(:,1) tfs(:,2) tfs(:,3)] = ...
         textread(fullfile(obj.DataDir,sprintf('H1to%dp',imgIdx)),...
         '%f %f %f%*[^\n]');
    end
  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      import datasets.*;
      installDir = VggAffineDataset.RootInstallDir;
      dstPaths = {fullfile(installDir,obj.Category)};
      urls = {[VggAffineDataset.RootUrl obj.Category '.tar.gz']};
    end
  end
end
