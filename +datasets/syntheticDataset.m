% TRANSFDATASET class to wrap around the vgg affine benchmark datasets

% TODO create metafiles with the configurations
classdef transfDataset < affineDetectors.genericDataset
  properties (SetAccess=private, GetAccess=public)
    opts
    image
    imageName
    imageExt
    transformations
    dataDir
  end

  properties (SetAccess=protected, GetAccess=protected)
    genImages
    genTfs
    doGenerate
  end

  properties (SetAccess=public, GetAccess=public)
    % None here
  end

  methods
    function obj = transfDataset(varargin)
      obj.opts.category= {'rotation'};
      obj.opts.image = '';
      obj.opts.numImages = 10;
      obj.opts.maxAngle = 180;
      obj.opts.startZoom = 1;
      obj.opts.endZoom = 2;
      obj.opts.minBlur = 1.2;
      obj.opts.maxBlur = 15;
      obj.opts.minNoise = 0.001;
      obj.opts.maxNoise = 0.01;
      obj.opts = commonFns.vl_argparse(obj.opts,varargin);
      if ~iscell(obj.opts.category)
        obj.opts.category = {obj.opts.category};
      end
      categoriesStr = [sprintf('%s-',obj.opts.category{1:end-1}), obj.opts.category{end}];
      for category=obj.opts.category
        assert(ismember(category{1},obj.allCategories),...
             sprintf('Invalid category for geometric transformatio dataset: %s\n',...
             category{1}));
      end
      obj.datasetName = ['transfDataset-' categoriesStr];
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      obj.numImages = obj.opts.numImages;
      [pathstr, obj.imageName, obj.imageExt] = fileparts(obj.opts.image);
      
      obj.dataDir = fullfile(cwd,obj.rootInstallDir,...
                             categoriesStr, obj.imageName);
      obj.image = imread(fullfile(cwd,obj.rootInstallDir,obj.opts.image));
      vl_xmkdir(obj.dataDir);
      obj.imageLabels = cell(obj.numImages,1);
      obj.imageLabelsTitle = 'Image ';
      
      % Check if images generated
      files = dir([obj.dataDir '/img*' obj.imageExt]);
      if numel(files) == obj.numImages
        fprintf('Transformations "%s" of image "%s" already exist.\n',...
          categoriesStr,obj.imageName);
        obj.doGenerate = false;
      else
        obj.doGenerate = true;
        
        % Generate transformed images and save them
        fprintf('Generating trnasformations "%s" of image "%s"...\n',...
        categoriesStr,obj.imageName);
        obj.genImages = cell(1,obj.numImages);
        obj.genImages(:) = {obj.image};
      end
      
      % Generate geometric transformations
      obj.genTfs = cell(1,obj.numImages);
      obj.genTfs(:) = {eye(3)};
      for category=obj.opts.category
        switch category{1}
          case 'rotation'
            obj.generateRotations();
          case 'zoom'
            obj.generateZooms();
          case 'noise'
            obj.generateNoises();
          case 'blur'
            obj.generateBlurs();
        end
      end
      
      if obj.doGenerate
        obj.deleteFiles(obj.dataDir,['img*' obj.imageExt]);
        obj.deleteFiles(obj.dataDir,'H*p');

        obj.saveGenImages;
        obj.saveGenTfs;
      
        obj.genImages = [];
      end
    end

    function imgPath = getImagePath(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.numImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.dataDir,sprintf('img%d%s',imgIdx,obj.imageExt));
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
    rootInstallDir = 'datasets/transfDataset/';
    allCategories = {'rotation','zoom','blur','noise'};
  end

  methods (Access=private)
    
    function deleteFiles(obj, path, pattern)
      files = dir([path '/' pattern]);
      fileNames = {files.name};
      if numel(fileNames) > 0
        for fn=1:numel(fileNames)
          delete(fullfile(path,fileNames{fn}));
          fprintf('Deleted file %s.\n',fileNames{fn});
        end
      end
    end
    
    function generateRotations(obj)
      obj.imageLabelsTitle = [obj.imageLabelsTitle 'rot. '];
      i = 1;
      angles = linspace(0, obj.opts.maxAngle,obj.numImages);
      for angle=angles
        obj.imageLabels{i} = [obj.imageLabels{i} num2str(angle,'%0.2f') '° '];
        if angle==0
          i = i + 1;
          continue;
        else
          tfs = obj.createRotation(angle);  
          obj.genTfs{i} = obj.genTfs{i} * tfs;
        end
        i = i + 1;
      end
      fprintf('Rotations: %s.\n',...
        [sprintf('%g°, ',angles(1:end-1)) num2str(angles(end))]);
    end
    
    function generateZooms(obj)
      obj.imageLabelsTitle = [obj.imageLabelsTitle 'zoom '];
      i = 1;
      zooms = linspace(obj.opts.startZoom, obj.opts.endZoom,obj.numImages);
      for zoom=zooms
        obj.imageLabels{i} = [num2str(zoom,'%0.2f') 'x '];
        tfs = obj.createZoom(zoom);  
        obj.genTfs{i} = obj.genTfs{i} * tfs;
        
        % If the image is subsampled, filter the high frequencies
        if zoom < 1
          sigma = 1/zoom/2;
          filtrSize = round(6*sigma);
          filtr = fspecial('gaussian',[filtrSize filtrSize],sigma);
          obj.genImages{i} = imfilter(obj.image,filtr,'same');
        end
        i = i + 1;
      end
      fprintf('Scales: %s.\n',...
        [sprintf('%g, ',zooms(1:end-1)) num2str(zooms(end))]);
    end
    
    function generateNoises(obj)
      obj.imageLabelsTitle = [obj.imageLabelsTitle 'noise '];
      sigmas = linspace(obj.opts.minNoise,obj.opts.maxNoise,obj.numImages-1);
      i = 2;
      for sigma=sigmas
        obj.imageLabels{i} = ['\sigma_n=' num2str(sigma,'%0.2f') ' '];
        if obj.doGenerate
          obj.genImages{i} = imnoise(obj.genImages{i},'gaussian',0,sigma);
        end
        i = i + 1;
      end
      fprintf('Image noise sigmas: %s.\n',...
        [sprintf('%g, ',sigmas(1:end-1)) num2str(sigmas(end))]);
    end
    
    function generateBlurs(obj)
      obj.imageLabelsTitle = [obj.imageLabelsTitle 'blur '];
      sigmas = linspace(obj.opts.minBlur,obj.opts.maxBlur,obj.numImages-1);
      i = 2;
      for sigma=sigmas
        obj.imageLabels{i} = ['\sigma_b=' num2str(sigma,'%0.2f') ' '];
        if obj.doGenerate
          filtrSize = round(3*sigma);
          filtr = fspecial('gaussian',[filtrSize filtrSize],sigma);
          obj.genImages{i} = imfilter(obj.image,filtr,'same');
        end
        i = i + 1;
      end
      fprintf('Image blur sigmas: %s.\n',...
        [sprintf('%g, ',sigmas(1:end-1)) num2str(sigmas(end))]);
    end
    
    function saveGenImages(obj)
      for i=1:obj.numImages
        imgName = ['img',num2str(i),obj.imageExt];
        imageFileName = fullfile(obj.dataDir,imgName);
        obj.genImages{i} = obj.geomTransfImage(i);
        imwrite(obj.genImages{i},imageFileName);
        fprintf('Image "%s" generated and saved\n',imgName);
      end
    end

    function saveGenTfs(obj)      
      for i=1:obj.numImages
        if i==1
          continue;
        else
          obj.saveTransformation(obj.genTfs{i}, i);
        end
      end
    end

    function tfs = createRotation(obj, angleDeg)
      center = size(obj.image)./2;
      angleRad = angleDeg/180*pi;
      shift1 = [eye(2) [-center(2); -center(1)]; 0 0 1];
      shift2 = [eye(2) [center(2); center(1)];0 0 1];
      rot = [cos(angleRad) -sin(angleRad) 0;... 
             sin(angleRad) cos(angleRad) 0; 0 0 1];
      tfs = shift2 * rot * shift1;
    end
    
    function tfs = createZoom(obj, scale)
      center = size(obj.image)./2;
      shift1 = [eye(2) [-center(2); -center(1)]; 0 0 1];
      shift2 = [eye(2) [center(2); center(1)];0 0 1];
      zoom = [scale 0 0;... 
              0 scale 0; 0 0 1];
      tfs = shift2 * zoom * shift1;
    end
    
    function tImage = geomTransfImage(obj, i)
      tform = maketform('projective',obj.genTfs{i}');
      im = obj.genImages{i};
      tImage = imtransform(im,tform,'XData',[0 size(im,2)],'YData',...
        [0 size(im,1)],'UData',[0 size(im,2)],'VData',[0 size(im,1)]);   
    end
    
    function saveTransformation(obj,tfs,imageNum)
      transfFileName = fullfile(obj.dataDir,sprintf('H1to%dp',imageNum));
      file = fopen(transfFileName,'w');
      tfs = tfs'; % In the protocol inverse is saved
      for i=1:3
        fprintf(file,'%f %f %f\n',tfs(:,i));
      end
      fclose(file);
    end
  end
  
  methods (Static)
    function response = isInstalled()
      response = true;
    end

  end % --- end of static methods ---

end % -------- end of class ---------
