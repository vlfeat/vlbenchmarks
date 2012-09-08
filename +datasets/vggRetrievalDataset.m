% vggRetrievalDataset 

classdef vggRetrievalDataset < datasets.genericDataset & helpers.Logger
  properties (SetAccess=protected, GetAccess=public)
    category;
    dataDir;
    imdb;
    numQueries;
  end

  properties (Constant)
    rootInstallDir = fullfile('data','datasets','vggRetrievalDataset','');
    allCategories = {'oxbuild_lite'};
  end

  methods
    function obj = vggRetrievalDataset(varargin)
      import datasets.*;
      import helpers.*;
      if ~obj.isInstalled(),
        obj.warn('Vgg retreival dataset is not installed');
        vggRetrievalDataset.installDeps();
      end
      opts.category= obj.allCategories{1};
      opts = helpers.vl_argparse(opts,varargin);
      assert(ismember(opts.category,obj.allCategories),...
             sprintf('Invalid category for vgg retreival dataset: %s\n', ...
             opts.category));
      obj.datasetName = ['vggAffineDataset-' opts.category];
      obj.category= opts.category;
      obj.dataDir = fullfile(obj.rootInstallDir,opts.category,'');

      imdbPath = obj.getImdbFilePath(opts.category);
      obj.imdb = load(imdbPath);
      obj.numImages = numel(obj.imdb.images.id);
      obj.numQueries = numel(obj.imdb.queries);
    end

    function imgPath = getImagePath(obj,imgIdx)
      if imgIdx >= 1 && imgIdx <= obj.numImages
        imgPath = fullfile(obj.dataDir,obj.imdb.images.names{imgIdx});
      else
        obj.error('Out of bounds idx\n');
      end
    end

    function query = getQuery(obj,queryIdx)
      if queryIdx >= 1 && queryIdx <= obj.numQueries
        query = obj.imdb.queries(queryIdx);
      else
        obj.error('Out of bounds idx');
      end
    end

    function signature = getQueriesSignature(obj)
      import helpers.*;
      querySignatures = '';
      for queryIdx = 1:obj.numQueries
        query = obj.getQuery(queryIdx);
        querySignatures = strcat(querySignatures, obj.getQuerySignature(query));
      end
      signature = ['queries_' obj.datasetName CalcMD5.CalcMD5(querySignatures)];
    end

    function querySignature = getQuerySignature(obj, query)
      import helpers.*;
      imagePath = obj.getImagePath(query.imageId);
      imageSign = fileSignature(imagePath);
      querySignature = strcat(imageSign,mat2str(query.good),...
        mat2str(query.ok),mat2str(query.junk));
    end
  end

  methods(Static)
    function installDeps()
      import datasets.*;
      if(vggRetrievalDataset.isInstalled()),
        fprintf('vggRetrievalDataset already installed, nothing to do\n');
        return;
      end
      installDir = vggRetrievalDataset.rootInstallDir;
      for i = 1:numel(vggRetrievalDataset.allCategories)
        curCategory = vggRetrievalDataset.allCategories{i};
        catDir = fullfile(installDir,curCategory,'');
        if(~exist(catDir,'dir'))
          % TODO move bootstrap script to Matlab
          actDir = pwd;
          bootstrapScript = fullfile(pwd,'+datasets','retrieval-bootstrap.sh');
          cd installDir;
          system(bootstrapScript);
          cd actDir;
        end
        imdbPath = vggRetrievalDataset.getImdbFilePath(curCategory);
        if ~exist(imdbPath,'file')
          installDir = vggRetrievalDataset.rootInstallDir;
          gtPath = fullfile(installDir,[curCategory '_gt'],'');
          imdb = vggRetrievalDataset.preprocessImagesDir(catDir,gtPath);
          save(imdbPath, '-STRUCT', 'imdb');
        end
      end
    end

    function imdb = preprocessImagesDir(imPath, gtPath)
      import datasets.*;
      
      names = dir(fullfile(imPath, '*.jpg')) ;

      imdb.dir = imPath ;
      imdb.images.id = 1:numel(names) ;
      imdb.images.names = {names.name} ;

      numImages = numel(imdb.images.id);
      postfixless = cell(numImages,1);
      for i = 1:numImages
        [ans,postfixless{i}] = fileparts(imdb.images.names{i}) ;
      end
      function i = toindex(x)
        [ok,i] = ismember(x,postfixless) ;
        i = i(ok) ;
      end
      names = dir(fullfile(gtPath,'*_query.txt'));
      names = {names.name} ;
      if numel(names) == 0
        obj.warn('No queries in %s',gtPath);
      end
      for i = 1:numel(names)
        base = names{i} ;
        [imageName,x0,y0,x1,y1] = textread(fullfile(gtPath, base), '%s %f %f %f %f') ;
        name = base ;
        name = name(1:end-10) ;
        imageName = cell2mat(imageName) ;
        imageName = imageName(6:end) ;
        queries(i).name = name ;
        queries(i).imageName = imageName ;
        queries(i).imageId = toindex(imageName) ;
        queries(i).box = [x0;y0;x1;y1] ;
        queries(i).good = toindex(textread(fullfile(gtPath, sprintf('%s_good.txt',name)), '%s')) ;
        queries(i).ok = toindex(textread(fullfile(gtPath, sprintf('%s_ok.txt',name)), '%s')) ;
        queries(i).junk = toindex(textread(fullfile(gtPath, sprintf('%s_junk.txt',name)), '%s')) ;
      end

      % check for empty queries due to subsetting of the data
      ok = true(1,numel(queries)) ;
      for i = 1:numel(queries)
        ok(i) = ~isempty(queries(i).imageId) & ...
                ~isempty(queries(i).good) ;
      end
      queries = queries(ok) ;
      imdb.queries = queries;
      fprintf('%d of %d are covered by the selected database subset\n',sum(ok),numel(ok)) ;
    end

    function response = isInstalled()
      import datasets.*;
      response = false;
      installDir = vggRetrievalDataset.rootInstallDir;
      for i = 1:numel(vggRetrievalDataset.allCategories)
        curCategory = vggRetrievalDataset.allCategories{i};
        catDir = fullfile(installDir,curCategory,'');
        imdbPath = vggRetrievalDataset.getImdbFilePath(curCategory);
        if(~exist(catDir,'dir')), return; end
        if(~exist(imdbPath,'file')), return; end
      end
      response = true;
    end

    function path = getImdbFilePath(category)
      installDir = datasets.vggRetrievalDataset.rootInstallDir;
      path = fullfile(installDir,[category,'_imdb.mat']);
    end
  end
end % -------- end of class ---------
