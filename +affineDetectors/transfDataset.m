% TRANSFDATASET class to wrap around the vgg affine benchmark datasets

classdef transfDataset < affineDetectors.genericDataset
  properties (SetAccess=private, GetAccess=public)
    opts
    image
    imageName
    imageExt
    transformations
    dataDir
  end

  properties (SetAccess=public, GetAccess=public)
    % None here
  end

  methods
    function obj = transfDataset(varargin)
      obj.opts.category= 'rotation';
      obj.opts.image = '';
      obj.opts.numImages = 10;
      obj.opts = commonFns.vl_argparse(obj.opts,varargin);
      assert(ismember(obj.opts.category,obj.allCategories),...
             sprintf('Invalid category for geometric transformatio dataset: %s\n',...
             obj.opts.category));
      obj.datasetName = ['transfDataset-' obj.opts.category];
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      obj.image = imread(fullfile(cwd,obj.rootInstallDir,obj.opts.image));
      obj.numImages = obj.opts.numImages;
      [pathstr, obj.imageName, obj.imageExt] = fileparts(obj.opts.image);
      
      obj.dataDir = fullfile(cwd,obj.rootInstallDir,...
                             obj.opts.category, obj.imageName);
      vl_xmkdir(obj.dataDir);
      
      switch obj.opts.category
        case 'rotation'
          obj.generateRotations();
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
    allCategories = {'rotation'};
    maxAngle = 180;
  end

  methods (Access=private)
    function generateRotations(obj)
      files = dir([obj.dataDir '/*.pgm']);
      if numel(files) == obj.numImages
        fprintf('Rotations of image %s already created.\n',obj.imageName);
        return;
      end
      
      fileNames = {files.name};
      if numel(fileNames) > 0
        for fn=1:numel(fileNames)
          delete(fullfile(obj.dataDir,fileNames{fn}));
        end
      end
      i = 1;
      
      for angle=linspace(0, obj.maxAngle,obj.numImages)
        imageFileName = fullfile(obj.dataDir,['img',num2str(i),obj.imageExt]);
        
        if angle==0
          imwrite(obj.image,imageFileName);
        else
          tfs = obj.createRotation(angle);
          rotImage = obj.geomTransfImage(tfs);
          imwrite(rotImage,imageFileName);

          obj.saveTransformation(tfs, i);
          fprintf('Image %s with rotation of %0.3g° created\n',...
                  obj.imageName,angle);
        end
        i = i + 1;
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
    
    function tImage = geomTransfImage(obj, tfs)
      tform = maketform('projective',tfs');
      im = obj.image;
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
