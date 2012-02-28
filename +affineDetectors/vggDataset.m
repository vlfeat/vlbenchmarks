% VGGDATASET class to wrap around the vgg affine benchmark datasets
%
% The dataset is available at: http://www.robots.ox.ac.uk/~vgg/research/affine/

classdef vggDataset < affineDetectors.genericDataset
  properties (SetAccess=private, GetAccess=public)
    category
    dataDir
    imgExt
  end

  properties (SetAccess=public, GetAccess=public)
    % None here
  end

  methods
    function obj = vggDataset(varargin)
      if ~obj.isInstalled(),
        error('Vgg dataset is not installed, download and install it using affineDetectors.vggDataset.installDeps()\n');
      end
      opts.category= 'graf';
      opts = commonFns.vl_argparse(opts,varargin);
      assert(ismember(opts.category,obj.allCategories),...
             sprintf('Invalid category for vgg dataset: %s\n',opts.category));
      obj.datasetName = ['vggDataset_' opts.category];
      obj.category= opts.category;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      obj.dataDir = fullfile(cwd,obj.rootInstallDir,opts.category);
      obj.numImages = 6;
      if exist(fullfile(obj.dataDir,'img1.ppm')), obj.imgExt = 'ppm';
      else obj.imgExt = 'pgm'; end
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

  properties (Constant)
    rootInstallDir = 'datasets/vggDataset/';
    allCategories = {'bikes','trees','graf','wall','bark',...
                     'boat','leuven','ubc'};
    rootUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/';
  end

  methods (Static)
    function installDeps()
      import affineDetectors.*;
      if(vggDataset.isInstalled()),
        fprintf('VggDataset already installed, nothing to do\n');
        return;
      end

      fprintf('Downloading vgg dataset to: %s \n',vggDataset.rootInstallDir);

      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggDataset.rootInstallDir);

      allCategories = vggDataset.allCategories;
      for i = 1:numel(allCategories)
        curCategory = allCategories{i};
        fprintf('  Downloading %s dataset ...\n',curCategory);
        downloadUrl = [vggDataset.rootUrl curCategory '.tar.gz'];
        outDir = fullfile(installDir,curCategory);
        commonFns.vl_xmkdir(outDir);
        untar(downloadUrl,outDir);
      end

      fprintf('Vgg dataset download and install complete\n\n');

    end

    function response = isInstalled()
      import affineDetectors.*;
      response = false;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggDataset.rootInstallDir);
      for i = 1:numel(vggDataset.allCategories)
        curCategory = vggDataset.allCategories{i};
        tmpDir = fullfile(installDir,curCategory);
        if(~exist(tmpDir,'dir')), return; end
      end
      response = true;
    end

  end % --- end of static methods ---

end % -------- end of class ---------
