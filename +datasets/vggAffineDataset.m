% VGGAFFINEDATASET class to wrap around the vgg affine benchmark datasets
%
%   The dataset is available at: http://www.robots.ox.ac.uk/~vgg/research/affine/
%
%   obj = localFeatures.vggAffineDataset('Option','OptionValue',...)
%
%   Following options are supported:
%
%   Category :: ['graf']
%     The category within the vgg dataset, has to be one of 'bikes','trees',
%     'graf','wall','bark','boat','leuven','ubc'

classdef vggAffineDataset < datasets.genericTransfDataset
  properties (SetAccess=private, GetAccess=public)
    category
    dataDir
    imgExt
  end

  properties (Constant)
    rootInstallDir = fullfile('data','datasets','vggAffineDataset','');
    allCategories = {'bikes','trees','graf','wall','bark',...
                     'boat','leuven','ubc'};
    rootUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/';
  end

  
  methods
    function obj = vggAffineDataset(varargin)
      if ~obj.isInstalled(),
        warning('Vgg dataset is not installed');
        datasets.vggAffineDataset.installDeps();
      end
      opts.category= 'graf';
      opts = helpers.vl_argparse(opts,varargin);
      assert(ismember(opts.category,obj.allCategories),...
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
      imageLabels = textscan(num2str(1:obj.numImages),'%s');
      obj.imageNames = cellstr(imageLabels{1});
      obj.imageNamesLabel = 'Image #';
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
          textread(fullfile(obj.dataDir,sprintf('H1to%dp',imgIdx)),'%f %f %f%*[^\n]');
    end

  end

  methods (Static)
    function cleanDeps()
      import datasets.*;
      installDir = vggAffineDataset.rootInstallDir;

      fprintf('\nDeleting vgg dataset in: %s \n',vggAffineDataset.rootInstallDir);
      if(exist(installDir,'dir'))
        rmdir(installDir,'s');
        fprintf('Vgg dataset deleted\n');
      else
        fprintf('Vgg dataset not installed, nothing to delete\n');
      end


    end

    function installDeps()
      import datasets.*;
      if(vggAffineDataset.isInstalled()),
        fprintf('vggAffineDataset already installed, nothing to do\n');
        return;
      end

      fprintf('Downloading vgg dataset to: %s \n',vggAffineDataset.rootInstallDir);

      installDir = vggAffineDataset.rootInstallDir;

      allCategories = vggAffineDataset.allCategories;
      for i = 1:numel(allCategories)
        curCategory = allCategories{i};
        fprintf('  Downloading %s dataset ...\n',curCategory);
        downloadUrl = [vggAffineDataset.rootUrl curCategory '.tar.gz'];
        outDir = fullfile(installDir,curCategory);
        helpers.vl_xmkdir(outDir);
        untar(downloadUrl,outDir);
      end

      fprintf('Vgg dataset download and install complete\n\n');

    end

    function response = isInstalled()
      import datasets.*;
      response = false;
      installDir = vggAffineDataset.rootInstallDir;
      for i = 1:numel(vggAffineDataset.allCategories)
        curCategory = vggAffineDataset.allCategories{i};
        tmpDir = fullfile(installDir,curCategory);
        if(~exist(tmpDir,'dir')), return; end
      end
      response = true;
    end

  end % --- end of static methods ---

end % -------- end of class ---------
