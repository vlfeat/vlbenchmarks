classdef HannoverAffineDataset < datasets.GenericTransfDataset & helpers.Logger...
    & helpers.GenericInstaller
% datasets.VggAffineDataset Wrapper around the vgg affine datasets
%   datasets.VggAffineDataset('Option','OptionValue',...) Constructs
%   an object which implements access to VGG Affine dataset used for
%   affine invariant detectors evaluation.
%
%   http://www.tnt.uni-hannover.de/project/feature_evaluation/
%
%   This class perform automatic installation when the dataset data
%   are not available.
%
%   Following options are supported:
%
%   Category :: ['graf']
%     The category within the VGG dataset, has to be one of
%     'graf','bark','bikes','grace','underground','colors','posters','there'
%
% References:
%   [1] Kai Cordes, Bodo Rosenhahn, Jörn Ostermann Increasing the 
%       Accuracy of Feature Evaluation Benchmarks Using Differential 
%       Evolution, IEEE Symposium Series on Computational Intelligence,
%       2011

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Category = 'graf'; % Dataset category
    DataDir; % Image location
    ImgExt; % Image extension
    RefImageSize;
  end

  properties (Constant)
    % All dataset categories
    AllCategories = {'graf','bark','bikes','grace','underground',...
      'colors','posters','there'};
  end

  properties (Constant, Hidden)
    SourceName = 'HannoverAffineDataset';
    % Installation directory
    RootInstallDir = fullfile('data','datasets','hannoverAffineDataset','');
    % Names of the image transformations in particular categories
    CategoryImageNames = containers.Map(...
      datasets.HannoverAffineDataset.AllCategories, {...
      'Viewpoint angle',... % graf
      'Scale changes',... % bark
      'Increasing blur',... % bikes
      'Viewpoint change',... % grace
      'Viewpoint change + patt. rep.',... % underground
      'Viewpoint change + patt. rep.',... % colors
      'Viewpoint change + text. rep.',... % posters
      'Viewpoint change' ... % there
      });
    CategoryPackageNames = containers.Map(...
      datasets.HannoverAffineDataset.AllCategories, {...
      'GrafHomAcc',... % graf
      'BarkHomAcc',... % bark
      'BikesHomAcc',... % bikes
      'grace',... % grace
      'underground',... % underground
      'colors',... % colors
      'posters',... % posters
      'there' ... % there
      });
    % Image labels for particular categories (degree of transf.)
    CategoryImageLabels = containers.Map(...
      datasets.HannoverAffineDataset.AllCategories, {...
      [20 30 40 50 60],... % graf
      [1.2 1.8 2.5 3 4],...   % bark
      [2 3 4 5 6],... % bikes
      2:5,... % grace
      2:5,... % underground
      2:5,... % colors
      2:5,... % posters
      2:5 ... % there
      });
    % Root url for dataset tarballs
    RootUrl = 'http://www.tnt.uni-hannover.de/project/feature_evaluation/%s/%s.tar.gz';
    % Some datasets needs VGG Affine dataset data
    AdditionalArchives = containers.Map(...
      datasets.HannoverAffineDataset.AllCategories, {...
      {},{[datasets.VggAffineDataset.RootUrl 'bark.tar.gz']},...
      {[datasets.VggAffineDataset.RootUrl 'bikes.tar.gz']},...
      {},{},{},{},{}});
  end
  
    methods
    function obj = HannoverAffineDataset(varargin)
      import datasets.*;
      import helpers.*;
      opts.Category = obj.Category;
      [opts varargin] = vl_argparse(opts,varargin);
      valid = ismember(opts.Category,obj.AllCategories);
      assert(valid,...
        sprintf('Invalid category: %s\n',opts.Category));
      obj.DatasetName = [obj.SourceName opts.Category];
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
      obj.ImageNames = obj.CategoryImageLabels(opts.Category);
      obj.ImageNamesLabel = obj.CategoryImageNames(opts.Category);
      obj.RefImageSize = helpers.imageSize(obj.getImagePath(1));
    end

    function imgPath = getImagePath(obj,imgNo)
      assert(imgNo >= 1 && imgNo <= obj.NumImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.DataDir,sprintf('img%d.%s',imgNo,obj.ImgExt));
    end

    function sceneGeometry = getSceneGeometry(obj,imgNo)
      import consistencyModels.*;
      assert(imgNo >= 1 && imgNo <= obj.NumImages,'Out of bounds idx\n');
      if(imgNo == 1)
        tfs = eye(3);
        testImgSize = obj.RefImageSize;
      else
        tfs = zeros(3,3);
        [tfs(:,1) tfs(:,2) tfs(:,3)] = ...
           textread(fullfile(obj.DataDir,sprintf('H1to%dp',imgNo)),...
          '%f %f %f%*[^\n]');
        testImgSize = helpers.imageSize(obj.getImagePath(imgNo));
      end
      sceneGeometry = HomographyConsistencyModel.createSceneGeometry(tfs, ...
        obj.RefImageSize, testImgSize);
    end
  end

  methods (Access = protected)
    function [urls dstPaths] = getTarballsList(obj)
      import datasets.*;
      installDir = HannoverAffineDataset.RootInstallDir;
      dstPaths = {fullfile(installDir,obj.Category)};
      pkgName = obj.CategoryPackageNames(obj.Category);
      urls = {sprintf(obj.RootUrl,obj.Category,pkgName)};
      urls = [urls obj.AdditionalArchives(obj.Category)];
    end
  end
end
