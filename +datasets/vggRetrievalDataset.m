% VGGRETRIEVALDATASET Wrapper of VGG image retrieval datasets.
%   This class handles VGG image retrieval datasets [1] of images which are
%   accompanied with groundtruth queries. In these datasets each query q
%   specify following data:
%
%     q.name - Name of the query
%     q.imageName - Name of the image file which contain the query region
%     q.imageId - Unique identifier of the query image.
%     q.box [xmin ymin xmax ymax] - Box of the query region
%
%   And three sets of image ids [1]:
%     q.good -  A nice, clear picture of the object/building
%     q.ok - More than 25% of the object is clearly visible.
%     q.junk - Less than 25% of the object is visible, or there are very 
%       high levels of occlusion or distortion.
%
%   Images which are not present in these three sets are considered to be
%   in a 'bad' set, i.e. object is not present.
%
%   This class allows to pick only a susbset of the database by defining
%   the 'Lite' parameter to true. In this case, all images from query sets
%   'good' and 'ok' are preserved together with a subset of 'junk' sets
%   (defined by 'LiteJunkImagesNum' parameter). This limits the number of
%   irrelevant images for each query therefore improves the retrieval
%   performance. Main purpose of the lite dataset is to limit number of
%   images and therefore make the testing faster.
%
%   Downloaded data are parsed and a database of the images and queries is
%   created and on default is cached. However the validity of cached data
%   is checked only based on the class options and not on the files.
%   Therefore if you want change the contents of the database, make sure
%   that caching is disabled (option 'CacheDatabase').
%
% Options:
%   Category :: 'oxbuild'
%     Dataset category. Available are 'oxbuild'.
%
%   Lite :: true
%     Use only a subset of the whole database. All images from 'good' and 
%     'ok' sets of used queries are preserved and only a subset of 'junk'
%     images is preserved (defined by 'LiteJunkImagesNum' parameter).
%
%   LiteJunkImagesNum :: 300
%     Number of 'junk' images preserved in the databse.
%
%   CacheDatabase :: true
%     Cache parsed images and queries database.
%
%   REFERENCES
%   [1] J. Philbin, O. Chum, M. Isard, J. Sivic and A. Zisserman.
%       Object retrieval with large vocabularies and fast spatial matching
%       CVPR, 2007

classdef vggRetrievalDataset < datasets.genericDataset & helpers.Logger ...
    & helpers.GenericInstaller
  properties (SetAccess=protected, GetAccess=public)
    opts;
    imagesDir;  % Directory with current category images
    gtDir;      % Directory with current category ground truth data
    images;     % Array of structs defining the dataset images
    queries;    % Array of structs with the dataset queries
    numQueries; % Number of queries
  end

  properties (Constant)
    rootInstallDir = fullfile('data','datasets','vggRetrievalDataset','');
    allCategories = {'oxbuild'};
    imagesUrls = {'http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/oxbuild_images.tgz'};
    gtDataUrls = {'http://www.robots.ox.ac.uk/~vgg/data/oxbuildings/gt_files_170407.tgz'};
    % Default values
    defCategory = 'oxbuild';
    defLite = true;
    defLiteJunkImagesNum = 300;
    defCacheDatabase = true;
  end

  methods
    function obj = vggRetrievalDataset(varargin)
      % OBJ = VGGRETRIEVALDATASET('OptionName',OptionValue)
      %   Constructs the object of the retrieval dataset with the given
      %   option. For details see the class documentation.
      import datasets.*;
      import helpers.*;
      if ~obj.isInstalled(),
        obj.warn('Vgg retreival dataset is not installed');
        obj.install();
      end
      obj.opts.category= obj.defCategory;
      obj.opts.lite = obj.defLite;
      obj.opts.liteJunkImagesNum = obj.defLiteJunkImagesNum;
      obj.opts.cacheDatabase = obj.defCacheDatabase;
      [obj.opts varargin] = helpers.vl_argparse(obj.opts,varargin);
      assert(ismember(obj.opts.category,obj.allCategories),...
             sprintf('Invalid category for vgg retreival dataset: %s\n',...
             obj.opts.category));
      obj.datasetName = ['vggRetrievalDataset-' obj.opts.category];
      if obj.opts.lite
        obj.datasetName = [obj.datasetName '-lite'];
      end
      obj.configureLogger(obj.datasetName, varargin);
      obj.imagesDir = fullfile(obj.rootInstallDir,obj.opts.category,'');
      obj.gtDir = fullfile(obj.rootInstallDir,...
        [obj.opts.category '_gt'],'');

      if obj.opts.cacheDatabase
        dataKey = [obj.datasetName ';' struct2str(obj.opts)];
        data = DataCache.getData(dataKey);
        if ~isempty(data)
          obj.debug('Database loaded from cache.');
          [obj.images obj.queries] = data{:};
        else
          [obj.images obj.queries] = obj.buildImageDatabase();
          DataCache.storeData({obj.images obj.queries},dataKey);
        end
      else
        [obj.images obj.queries] = obj.buildImageDatabase();
      end
      obj.numImages = numel(obj.images.id);
      obj.numQueries = numel(obj.queries);
    end

    function imgPath = getImagePath(obj,imageNo)
      % GETIMAGEPATHB Get a path of an image from the database.
      %   IMG_PATH = GETIMAGEPATH(IMG_NO) Get path IMG_PATH of an image 
      %   defined by its number 0 < IMG_NO < obj.numImages. When a subset
      %   of images is used, only this subset of images can be accessed
      %   with this method.
      if imageNo >= 1 && imageNo <= obj.numImages
        imgPath = fullfile(obj.imagesDir,obj.images.names{imageNo});
      else
        obj.error('Out of bounds image number.\n');
      end
    end

    function query = getQuery(obj,queryIdx)
      % GETQUERY Get a dataset query
      %  QUERY = GETQUERY(QUERYID) Returns struct QUERY defined by 
      %    0 < QUERYID < obj.numQueries. For query definition see class
      %    documentation.
      if queryIdx >= 1 && queryIdx <= obj.numQueries
        query = obj.queries(queryIdx);
      else
        obj.error('Out of bounds idx');
      end
    end

    function signature = getQueriesSignature(obj)
      % GETQUERIESSIGNATURE Get signature of all dataset queries
      %   SIGNATURE = GETQUERIESSIGNATURE() Get a unique signature of all
      %   queries in the dataset.
      import helpers.*;
      querySignatures = '';
      for queryIdx = 1:obj.numQueries
        query = obj.getQuery(queryIdx);
        querySignatures = strcat(querySignatures, obj.getQuerySignature(query));
      end
      signature = ['queries_' obj.datasetName CalcMD5.CalcMD5(querySignatures)];
    end

    function querySignature = getQuerySignature(obj, query)
      % GETQUERYSIGNATURE Get a signature of a query
      %  QUERY_SIGNATURE = GETQUERYSIGNATURE(QUERY) Get an unique string
      %  signatures QUERY_SIGNATURE of a query struct. QUERY.
      import helpers.*;
      imagePath = obj.getImagePathById(query.imageId);
      imageSign = fileSignature(imagePath);
      querySignature = strcat(imageSign,mat2str(query.good),...
        mat2str(query.ok),mat2str(query.junk));
    end
  end

  methods(Access = protected)
    function [images queries] = buildImageDatabase(obj)
      import datasets.*;
      obj.info('Loading dataset %s.',obj.datasetName);
      names = dir(fullfile(obj.imagesDir, '*.jpg')) ;
      numImages = numel(names);
      images.id = 1:numImages ;
      images.names = {names.name} ;

      postfixless = cell(numImages,1);
      for i = 1:numImages
        [ans,postfixless{i}] = fileparts(images.names{i}) ;
      end
      function i = toindex(x)
        [ok,i] = ismember(x,postfixless) ;
        i = i(ok) ;
      end
      names = dir(fullfile(obj.gtDir,'*_query.txt'));
      names = {names.name} ;
      if numel(names) == 0
        obj.warn('No queries in %s',obj.gtDir);
      end

      for i = 1:numel(names)
        base = names{i} ;
        [imageName,x0,y0,x1,y1] = textread(fullfile(obj.gtDir, base), ...
          '%s %f %f %f %f') ;
        name = base ;
        name = name(1:end-10) ;
        imageName = cell2mat(imageName) ;
        imageName = imageName(6:end) ;
        queries(i).name = name ;
        queries(i).imageName = imageName ;
        queries(i).imageId = toindex(imageName) ;
        queries(i).box = [x0;y0;x1;y1] ;
        queries(i).good = toindex(textread(fullfile(obj.gtDir, ...
          sprintf('%s_good.txt',name)), '%s'))' ;
        queries(i).ok = toindex(textread(fullfile(obj.gtDir, ...
          sprintf('%s_ok.txt',name)), '%s'))' ;
        queries(i).junk = toindex(textread(fullfile(obj.gtDir, ...
          sprintf('%s_junk.txt',name)), '%s'))' ;
      end

      if obj.opts.lite
        goodImages = [queries(:).good];
        okImages = [queries(:).ok];
        junkImages = [queries(:).junk];
        numJunkImages = obj.opts.liteJunkImagesNum;

        % This method of picking images suppose that query images are part
        % of the good set
        pickedImages = [goodImages, okImages, junkImages(1:numJunkImages)];
        pickedImages = unique(pickedImages);
        obj.debug('Number of Lite images: %d',numel(pickedImages));
        
        % Change the queries for the picked image subset
        map = zeros(1,numImages);
        map(pickedImages) = 1:numel(pickedImages);
        for i=1:numel(queries)
          queries(i).imageId = map([queries(i).imageId]);
          queries(i).good = map([queries(i).good]);
          queries(i).ok = map([queries(i).ok]);
          queries(i).junk = map([queries(i).junk]);
        end
        images.id = 1:numel(pickedImages);
        images.names = images.names(pickedImages);
      end
    end
  end

  methods (Static)
    function [urls dstPaths] = getTarballsList()
      import datasets.*;
      numCategories = numel(vggRetrievalDataset.allCategories);
      urls = cell(1,numCategories*2);
      dstPaths = cell(1,numCategories*2);
      installDir = vggRetrievalDataset.rootInstallDir;
      for i = 1:numCategories
        curCategory = vggRetrievalDataset.allCategories{i};
        % Images
        urls{2*(i-1)+1} = vggRetrievalDataset.imagesUrls{i};
        dstPaths{2*(i-1)+1} = fullfile(installDir,curCategory);
        % Ground truth data
        urls{2*(i-1)+2} = vggRetrievalDataset.gtDataUrls{i};
        dstPaths{2*(i-1)+2} = fullfile(installDir,[curCategory '_gt']);
      end
    end
  end
end % -------- end of class ---------
