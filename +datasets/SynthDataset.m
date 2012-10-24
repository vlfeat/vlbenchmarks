% SYNTHDATASET
classdef SynthDataset < datasets.GenericTransfDataset & helpers.Logger
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
    MaxLatitude = 85/180*pi;
    GaussK = 3;
    BlurTypes = {'gaussian','motion','median'};
    NoiseTypes = {'gaussian','localvar','salt & pepper','speckle'};
    GradientTypes = {'circular','linleft','linright','linup','lindown'};
  end

  methods
    function obj = SynthDataset(imagePath, numImages, cropImage, varargin)
      import helpers.*;
      obj.NumImages = numImages;
      obj.CropImage = cropImage;
      obj.DatasetName = 'Synth. Dataset';
      [pathstr, obj.ImageName, obj.ImageExt] = fileparts(imagePath);

      transformations = {};
      transfNames = {};
      for iv=1:numel(varargin)
        if iscell(varargin{iv})
          [transformations{iv} transfNames{iv}] = varargin{iv}{:};
        else
          iv = iv - 1;
          break;
        end
      end
      obj.configureLogger(obj.DatasetName,varargin(iv+1:end));
      if obj.CropImage, cropStr = 'c'; else cropStr = 'u'; end;
      transfName = [sprintf('%s%d_',cropStr,numImages) ...
        cell2str(transfNames,'_')];
      obj.DataDir = fullfile(obj.RootDir,...
        obj.ImageName,transfName);
      obj.ImageNames = cell(obj.NumImages,1);

      % Check whether images already generated
      imgFiles = dir(fullfile(obj.DataDir, ['img*' obj.ImageExt]));
      tfsFiles = dir(fullfile(obj.DataDir, 'H1to*p'));
      if numel(imgFiles) == numImages && numel(tfsFiles) == numImages - 1
        obj.info('Transformations "%s" of image "%s" already exist.',...
          transfName,obj.ImageName);
        % Generate image names
        for tfh = transformations, tfh{1}(obj); end
        return;
      else
        % Generate transformed images and save them
        obj.Image = imread(imagePath);
        vl_xmkdir(obj.DataDir);
        obj.info('Generating transformations "%s" of image "%s"...',...
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
      assert(imgIdx >= 1 && imgIdx <= obj.NumImages,'Out of bounds idx');
      imgPath = fullfile(obj.DataDir,sprintf('img%d%s',imgIdx,obj.ImageExt));
    end

    function tfs = getTransformation(obj,imgIdx)
      assert(imgIdx >= 1 && imgIdx <= obj.NumImages,'Out of bounds idx');
      if(imgIdx == 1), tfs = eye(3); return; end
      tfs = zeros(3,3);
      [tfs(:,1) tfs(:,2) tfs(:,3)] = ...
        textread(fullfile(obj.DataDir,sprintf('H1to%dp',imgIdx)),...
        '%f %f %f%*[^\n]');
    end
  end

  methods (Static)
    function res = scale(scales)
      if ~exist('scales','var'), scales = [1 2]; end;
      res = {@(obj) obj.generateScales(scales)
        sprintf('scale-%0.2f-%0.2f',scales(1),scales(end))};
    end

    function res = rotation(angles)
      if ~exist('angles','var'), angles = [0 pi]; end;
      res = {@(obj) obj.generateRotations(angles)
        sprintf('rot-%d-%d',round(angles(1)/pi*180), ...
        round(angles(end)/pi*180))};
    end

    function res = affineViewpoint(latitudes, longitudes)
      if ~exist('latitudes','var'), latitudes = [0 pi/4]; end;
      if ~exist('longitudes','var'), longitudes = [0 pi/4]; end;
      res = {@(obj) obj.generateAffVpt(latitudes, longitudes)
        sprintf('aff-vpt-lat%d-%d-long%d-%d',round(latitudes(1)/pi*180),...
        round(latitudes(end)/pi*180),round(longitudes(1)/pi*180),...
        round(longitudes(end)/pi*180))};
    end

    function res = noise(noiseType, noiseValues)
      import datasets.*;
      if ~exist('noiseVals','var'), noiseValues = [0.001 0.01]; end;
      if ~exist('noiseType','var'), noiseType = 'gaussian'; end;
      if ~ismember(noiseType,SynthDataset.NoiseTypes)
        error('Invalid noise type %s',blurType); 
      end;
      res = {@(obj) obj.generateNoise(noiseType, noiseValues)
        sprintf('noise-%s-%0.3f-%0.3f',...
        noiseType, noiseValues(1), noiseValues(end))};
    end

    function res = blur(blurType, sigmas)
      import datasets.*;
      if ~exist('sigmas','var'), sigmas = [1 4]; end;
      if ~exist('blurType','var'), blurType = 'gaussian'; end;
      if ~ismember(blurType,SynthDataset.BlurTypes)
        error('Invalid blur type %s',blurType); 
      end;
      res = {@(obj) obj.generateBlur(blurType, sigmas)
        sprintf('blur-%s-%0.2f-%0.2f',...
        blurType, sigmas(1), sigmas(end))};
    end

    function res = jpegCompression(imQualities)
      if ~exist('imQualities','var'), imQualities = [100 40]; end;
      res = {@(obj) obj.generateJpegCompression(imQualities)
        sprintf('jpeg-%d-%d',...
        round(imQualities(1)), round(imQualities(end)))};
    end

    function res = gradient(gradType, falloffs)
      import datasets.*;
      if ~exist('falloffs','var'), falloffs = [1 0.5]; end;
      if ~exist('gradType','var'), gradType = 'gaussian'; end;
      if ~ismember(gradType,SynthDataset.GradientTypes)
        error('Invalid gradient type %s',gradType); 
      end;
      res = {@(obj) obj.generateGradients(gradType, falloffs)
        sprintf('grad-%s-%0.2f-%0.2f',...
        gradType, falloffs(1), falloffs(end))};
    end

    function res = isInstalled()
      res = true;
    end
  end

  methods (Access = protected, Hidden)
    function params = checkParamsList(obj, params)
      if numel(params) ~= obj.NumImages
        if numel(params) == 2
          params = linspace(params(1),params(2),obj.NumImages);
        else
          error('Invladif number of transf. parameters.');
        end
      end
    end

    function generateRotations(obj, angles)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'rot. '];
      angles = obj.checkParamsList(angles);
      for i=1:numel(angles)
        angle = angles(i);
        obj.ImageNames{i} = [obj.ImageNames{i} ...
        num2str(angle/pi*180,'%0.2f') '° '];
        rot = [cos(angle) -sin(angle) 0;... 
           sin(angle) cos(angle) 0; 0 0 1];
        obj.GenTfs{i} = rot * obj.GenTfs{i};
      end
      obj.debug('Rotations: %s.',...
        [sprintf('%g°, ',angles(1:end-1)./pi*180) ...
        num2str(angles(end)/pi*180)]);
    end

    function generateScales(obj, scales)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'scale '];
      scales = obj.checkParamsList(scales);
      for i=1:numel(scales)
        scale = scales(i);
        obj.ImageNames{i} = num2str(scale,'%0.2f');
        if isempty(obj.Image), continue; end;
        tfs = [scale 0 0; 0 scale 0; 0 0 1];
        obj.GenTfs{i} = tfs * obj.GenTfs{i};
      end
      obj.debug('Scales: %s.',...
        [sprintf('%g, ',scales(1:end-1)) num2str(scales(end))]);
    end

    function generateAffVpt(obj, latitudes, longitudes)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'aff. vpt. [lat|long]'];
      latitudes = obj.checkParamsList(latitudes);
      longitudes = obj.checkParamsList(longitudes);
      if numel(latitudes) ~= numel(longitudes) 
        error('Number of alt. and long. values must be the same.'); 
      end
      if max(latitudes) > obj.MaxLatitude
        obj.warn('Longitude exceedes the maximal latitude.');
        latitudes(latitudes > obj.MaxLatitude) = obj.MaxLatitude;
      end
      for i = 1:numel(latitudes)
        lat = latitudes(i); long = longitudes(i);
        obj.ImageNames{i} = [obj.ImageNames{i} ...
        num2str(lat/pi*180,'%0.2f') '°|' ...
        num2str(long/pi*180,'%0.2f') '° '];
        if isempty(obj.Image), continue; end;
        rot = [cos(long) -sin(long) 0;... 
           sin(long) cos(long) 0; 0 0 1];
        tM = [diag([1 abs(cos(lat))]) zeros(2,1); 0 0 1];
        obj.GenTfs{i} = tM * rot * obj.GenTfs{i};
      end
      obj.debug('Longitudes: %s.',...
        [sprintf('%g°, ',longitudes(1:end-1)./pi*180) ...
        num2str(longitudes(end)/pi*180)]);
      obj.debug('Latitudes: %s.',...
        [sprintf('%g°, ',latitudes(1:end-1)./pi*180) ...
        num2str(latitudes(end)/pi*180)]);
    end

    function generateNoise(obj, noiseType, noiseValues)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'noise '];
      noiseValues = obj.checkParamsList(noiseValues);
      for i=1:numel(noiseValues)
        nval = noiseValues(i);
        obj.debug('Generating %s noise with val. %f.',noiseType,val);
        obj.ImageNames{i} = ['\sigma_n=' num2str(nval,'%0.2f') ' '];
        if isempty(obj.Image), continue; end;
        switch noiseType
          case 'gaussian'
          obj.GenImages{i} = imnoise(obj.GenImages{i},'gaussian',0,nval);
          case {'localvar','salt & pepper','speckle'}
          obj.GenImages{i} = imnoise(obj.GenImages{i},noiseType,nval);
          otherwise
          obj.err('Unsupported type of noise: %s',noiseType);
        end
      end
      obj.debug('Image noise sigmas: %s.',...
        [sprintf('%g, ',noiseValues(1:end-1)) num2str(noiseValues(end))]);
    end

    function generateBlur(obj, blurType, blurVals)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'blur '];
      blurVals = obj.checkParamsList(blurVals);
      for i = 1:numel(blurVals)
        val = blurVals(i);
        obj.debug('Bluring image with %s val. %f.',blurType, val);
        switch blurType
          case 'gaussian'
          obj.ImageNames{i} = ['\sigma_b=' num2str(val,'%0.2f') ' '];
          if isempty(obj.Image), continue; end;
          filterSize = round(obj.GaussK*val);
          filter = fspecial('gaussian',[filterSize filterSize],val);
          obj.GenImages{i} = imfilter(obj.GenImages{i},filter,'same');
          case 'motion'
          filterSize = round(val);
          obj.ImageNames{i} = ['\l=' num2str(filterSize,'%d') ' '];
          if isempty(obj.Image), continue; end;
          filter = fspecial('motion',filterSize,0);
          obj.GenImages{i} = imfilter(obj.GenImages{i},filter,'same');
          case 'median'
          filterSize = round(val);
          obj.ImageNames{i} = ['\d=' num2str(filterSize,'%d') ' '];
          if isempty(obj.Image), continue; end;
          obj.GenImages{i} = medfilt2(obj.GenImages{i},...
            [filterSize filterSize]);
          otherwise
          obj.error('Invalid blur type %s',blurType);
        end
      end
      obj.debug('Image blur values: %s.',...
        [sprintf('%g, ',blurVals(1:end-1)) num2str(blurVals(end))]);
    end

    function generateGradients(obj, gradType, fallOffs)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'int. grad. '];
      fallOffs = obj.checkParamsList(fallOffs);
      for i = 1:numel(fallOffs)
        foff = fallOffs(i);
        obj.debug('Generating %s gradient with foff %f.',gradType,foff);
        obj.ImageNames{i} = ['\foff=' num2str(foff,'%d') ' '];
        if foff == 1, continue; end;
        if isempty(obj.Image), continue; end;
        imgSize = size(obj.Image);
        switch gradType
          case 'linup'
          mask = repmat(linspace(foff,1,imgSize(1))',1,imgSize(2));
          case 'lindown'
          mask = repmat(linspace(1,foff,imgSize(1))',1,imgSize(2));
          case 'linleft'
          mask = repmat(linspace(foff,1,imgSize(2)),imgSize(1),1);
          case 'linright'
          mask = repmat(linspace(1,foff,imgSize(2)),imgSize(1),1);
          case 'circular'
          [x y] = ndgrid(1:imgSize(1),1:imgSize(2));
          center = imgSize./2;
          x = (x - center(1))./center(1); y = (y - center(2))./center(2);
          mask = (1 - sqrt(x.*x + y.*y)).*(1-foff) + foff;
          otherwise
          obj.error('Invalid gradient type %s',gradType);
        end
        mask = single(mask);
        obj.GenImages{i} = ...
          im2single(obj.GenImages{i}).*repmat(mask,[1,1,imgSize(3)]);
      end
      obj.debug('Image blur values: %s.',...
        [sprintf('%g, ',fallOffs(1:end-1)) num2str(fallOffs(end))]);
    end

    function generateJpegCompression(obj, imgQualities)
      obj.ImageNamesLabel = [obj.ImageNamesLabel 'jpeg comp. '];
      imQualities = round(obj.checkParamsList(imgQualities));
      for i = 1:numel(imQualities)
        imq = imQualities(i);
        obj.ImageNames{i} = ['jpeg_q=' num2str(imq,'%d') ' '];
        if isempty(obj.Image), continue; end;
        if imq == 100, continue; end;
        imFile = [tempname '.jpeg'];
        imwrite(obj.Image,imFile,'JPEG','Quality',imq);
        obj.GenImages{i} = imread(imFile);
        delete(imFile);
      end
      obj.debug('Jpeg compression qualities: %s.',...
        [sprintf('%d, ',imQualities(1:end-1)) num2str(imQualities(end))]);
    end

    function saveGeneratedTransformations(obj)
      baseTf = eye(3); % transformation of the first image
      for i=1:obj.NumImages
        imgName = ['img',num2str(i),obj.ImageExt];
        imageFileName = fullfile(obj.DataDir,imgName);
        tf = obj.GenTfs{i};
        % If the image is subsampled, filter the high frequencies
        if det(tf) < 1
          % Take the affine transformation in the centre point of the image
          % where the transformation is defined
          obj.info('Smoothing input image.');
          Aff = tf(1:2,1:2).*2;
          Sigma = inv(Aff'*Aff);
          filter = datasets.helpers.anisotropicGauss(Sigma);
          obj.GenImages{i} = imfilter(obj.Image,filter,'same');
        end
        center = size(obj.Image);
        center = center([2 1])'./2;
        centerImageTf = [eye(2) [-center(1); -center(2)]; 0 0 1];
        if obj.CropImage
          mvImgTf = [eye(2) [center(1); center(2)];0 0 1];
          xData = [0 size(obj.Image,2)];
          yData = [0 size(obj.Image,1)];
          tf = mvImgTf * tf * centerImageTf;
        else
          imgCrnrs = [-center center.*[1;-1] center center.*[-1;1]; ...
            ones(1,4)];
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
        % Transposed as Matlab uses row vectors in imtform definition
        tform = maketform('projective',tf');
        im = obj.GenImages{i};
        tImage = imtransform(im,tform,'XData',xData,'YData',...
          yData,'UData',[0 size(im,2)],'VData',[0 size(im,1)]);
        imwrite(tImage,imageFileName);
        if i==1, baseTf = tf; continue; end;
        % Save homography
        transfFileName = fullfile(obj.DataDir,sprintf('H1to%dp',i));
        file = fopen(transfFileName,'w');
        % Adjust the transformation to be a tform from the first image
        tf = tf / baseTf;
        tfi = tf'; % In the protocol inverse is saved
        for r=1:3
          fprintf(file,'%f %f %f\n',tfi(:,r));
        end
        fclose(file);
        obj.debug('Image "%s" generated and saved',imgName);
      end
    end
  end
end
