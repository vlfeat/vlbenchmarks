% SYNTHDATASET
classdef SynthDataset < datasets.GenericTransfDataset
  properties (SetAccess=private, GetAccess=public)
    ImageName
    DataDir
    CropImage
  end

  properties (SetAccess=protected, GetAccess=protected)
    GenImages
    GenTfs
    ImageExt
    Image
  end

  properties (Constant)
    RootDir = fullfile('data','datasets','synthDataset');
  end

  methods
    function obj = SynthDataset(imagePath, numImages, cropImage, varargin)
      import helpers.*;
      obj.NumImages = numImages;
      obj.CropImage = cropImage;
      obj.DatasetName = 'Synth. Dataset';
      [pathstr, obj.ImageName, obj.ImageExt] = fileparts(imagePath);

      transformations = cell(1,numel(varargin));
      transfNames = cell(1,numel(varargin));
      for iv=1:numel(varargin)
        [transformations{iv} transfNames{iv}] = varargin{iv}{:};
      end
      if obj.CropImage, cropStr = 'c'; else cropStr = 'u'; end;
      transfName = [sprintf('%s%d_',cropStr,numImages) cell2str(transfNames,'_')];
      obj.DataDir = fullfile(obj.RootDir,...
        obj.ImageName,transfName);
      vl_xmkdir(obj.DataDir);
      obj.Image = imread(imagePath);
      obj.ImageNames = cell(obj.NumImages,1);
      obj.ImageNamesLabel = 'Image ';

      % Check whether images already generated
      imgFiles = dir(fullfile(obj.DataDir, ['img*' obj.ImageExt]));
      tfsFiles = dir(fullfile(obj.DataDir, 'H1to*p'));
      if numel(imgFiles) == numImages && numel(tfsFiles) == numImages
        fprintf('Transformations "%s" of image "%s" already exist.\n',...
          transfName,obj.ImageName);
        return;
      else
        % Generate transformed images and save them
        fprintf('Generating transformations "%s" of image "%s"...\n',...
        transfName,obj.ImageName);
        obj.GenImages = cell(1,numImages);
        obj.GenImages(:) = {obj.Image};
        obj.GenTfs = cell(1,obj.NumImages);
        obj.GenTfs(:) = {eye(3)};
        % Apply transformations
        for tfh = transformations
          tfh{1}(obj);
        end
        obj.saveGeneratedTransformations();
        obj.GenImages = [];
      end
    end

    function imgPath = getImagePath(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.NumImages,'Out of bounds idx\n');
      imgPath = fullfile(obj.DataDir,sprintf('img%d%s',imgIdx,obj.ImageExt));
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

  methods (Static)
    function res = scale(minScale, maxScale)
      if ~exist('minScale','var'), minScale = 1; end;
      if ~exist('maxScale','var'), maxScale = 2; end;
      res = {@(obj) obj.generateScales(minScale, maxScale)
        sprintf('scale-%0.2f-%0.2f',minScale, maxScale)};
    end

    function res = rotation(minAngle, maxAngle)
      if ~exist('minAngle','var'), minAngle = 0; end;
      if ~exist('maxAngle','var'), maxAngle = pi; end;
      res = {@(obj) obj.generateRotations(minAngle, maxAngle)
        sprintf('rot-%d-%d',round(minAngle/pi*180),...
        round(maxAngle/pi*180))};
    end

    function res = noise(noiseType, minNoiseVal, maxNoiseVal)
      if ~exist('minNoiseVal','var'), minNoiseVal = 0.001; end;
      if ~exist('maxNoiseVal','var'), maxNoiseVal = 0.01; end;
      if ~exist('noiseType','var'), noiseType = 'gaussian'; end;
      if strcmp(noiseType,'poisson')
        error('Poisson noise not supported');
      end
      res = {@(obj) obj.generateNoise(noiseType, minNoiseVal, maxNoiseVal)
        sprintf('noise-%s-%0.3f-%0.3f',...
        noiseType, minNoiseVal, maxNoiseVal)};
    end

    function res = blur(blurType, minSigma, maxSigma)
      if ~exist('minSigma','var'), minSigma = 1; end;
      if ~exist('maxSigma','var'), maxSigma = 4; end;
      if ~exist('blurType','var'), blurType = 'gaussian'; end;
      res = {@(obj) obj.generateBlur(blurType, minSigma, maxSigma)
        sprintf('blur-%s-%0.2f-%0.2f',...
        blurType, minSigma, maxSigma)};
    end

    function res = isInstalled()
      res = true;
    end
  end

  methods (Access = protected, Hidden)
    function generateRotations(obj, minAngle, maxAngle)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'rot. '];
      i = 1;
      angles = linspace(minAngle, maxAngle, obj.NumImages);
      for angle=angles
        obj.ImageNames{i} = [obj.ImageNames{i} ...
          num2str(angle/pi*180,'%0.2f') '° '];
        if angle==0
          i = i + 1;
          continue;
        else
          tfs = obj.createRotationTfs(angle);  
          obj.GenTfs{i} = obj.GenTfs{i} * tfs;
        end
        i = i + 1;
      end
      fprintf('Rotations: %s.\n',...
        [sprintf('%g°, ',angles(1:end-1)./pi*180) ...
        num2str(angles(end)/pi*180)]);
    end

    function rot = createRotationTfs(obj, angle)
      rot = [cos(angle) -sin(angle) 0;... 
             sin(angle) cos(angle) 0; 0 0 1];
    end

    function generateScales(obj, minScale, maxScale)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'scale '];
      i = 1;
      scales = linspace(minScale, maxScale,obj.NumImages);
      for scale=scales
        obj.ImageNames{i} = [num2str(scale,'%0.2f') 'x '];
        tfs = obj.createScalingTfs(scale);  
        obj.GenTfs{i} = obj.GenTfs{i} * tfs;
        % If the image is subsampled, filter the high frequencies
        if scale < 1
          sigma = 1/scale/2;
          filterSize = round(6*sigma);
          filtr = fspecial('gaussian',[filterSize filterSize],sigma);
          obj.GenImages{i} = imfilter(obj.Image,filtr,'same');
        end
        i = i + 1;
      end
      fprintf('Scales: %s.\n',...
        [sprintf('%g, ',scales(1:end-1)) num2str(scales(end))]);
    end

    function tfs = createScalingTfs(obj, scale)
      tfs = [scale 0 0;... 
             0 scale 0; 0 0 1];
    end

    function generateNoise(obj, noiseType, minNoise, maxNoise)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'noise '];
      noiseValues = linspace(minNoise,maxNoise,obj.NumImages-1);
      i = 2;
      for nval=noiseValues
        obj.ImageNames{i} = ['\sigma_n=' num2str(nval,'%0.2f') ' '];
        switch noiseType
          case 'gaussian'
          obj.GenImages{i} = imnoise(obj.GenImages{i},'gaussian',0,nval);
          case {'localvar','salt & pepper','speckle'}
          obj.GenImages{i} = imnoise(obj.GenImages{i},noiseType,nval);
          otherwise
          error('Unsupported type of noise: %s',noiseType);
        end
        i = i + 1;
      end
      fprintf('Image noise sigmas: %s.\n',...
        [sprintf('%g, ',noiseValues(1:end-1)) num2str(noiseValues(end))]);
    end

    function generateBlur(obj, blurType, minBlurSigma, maxBlurSigma)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'blur '];
      sigmas = linspace(minBlurSigma,maxBlurSigma,obj.NumImages-1);
      i = 2;
      for sigma=sigmas
        obj.ImageNames{i} = ['\sigma_b=' num2str(sigma,'%0.2f') ' '];
        filtrSize = round(3*sigma);
        filtr = fspecial(blurType,[filtrSize filtrSize],sigma);
        obj.GenImages{i} = imfilter(obj.Image,filtr,'same');
        i = i + 1;
      end
      fprintf('Image blur sigmas: %s.\n',...
        [sprintf('%g, ',sigmas(1:end-1)) num2str(sigmas(end))]);
    end

    function saveGeneratedTransformations(obj)
      for i=1:obj.NumImages
        imgName = ['img',num2str(i),obj.ImageExt];
        imageFileName = fullfile(obj.DataDir,imgName);
        tf = obj.GenTfs{i};
        center = size(obj.Image);
        center = center([2 1])'./2;
        centerImageTf = [eye(2) [-center(1); -center(2)]; 0 0 1];
        if obj.CropImage
          mvImgTf = [eye(2) [center(1); center(2)];0 0 1];
          xData = [0 size(obj.Image,2)];
          yData = [0 size(obj.Image,1)];
          tf = mvImgTf * tf * centerImageTf;
        else
          imgCrnrs = [-center center.*[1;-1] center center.*[-1;1]; ones(1,4)];
          tfImgCrnrs = tf * imgCrnrs;
          tfImgCrnrs = tfImgCrnrs ./ repmat(tfImgCrnrs(3,:),3,1);
          xMin = floor(min(tfImgCrnrs(1,:)));
          xMax = ceil(max(tfImgCrnrs(1,:)));
          yMin = floor(min(tfImgCrnrs(2,:)));
          yMax = ceil(max(tfImgCrnrs(2,:)));
          xData = [0 xMax - xMin]; yData = [0 yMax - yMin];
          mvImgTf = [eye(2) [-xMin; -yMin];0 0 1];
          tf = mvImgTf * tf * centerImageTf;
        end
        tform = maketform('projective',tf');
        im = obj.GenImages{i};
        tImage = imtransform(im,tform,'XData',xData,'YData',...
          yData,'UData',[0 size(im,2)],'VData',[0 size(im,1)]);
        imwrite(tImage,imageFileName);
        % Save homography
        transfFileName = fullfile(obj.DataDir,sprintf('H1to%dp',i));
        file = fopen(transfFileName,'w');
        tfi = tf'; % In the protocol inverse is saved
        for r=1:3
          fprintf(file,'%f %f %f\n',tfi(:,r));
        end
        fclose(file);
        fprintf('Image "%s" generated and saved\n',imgName);
      end
    end
  end
end
