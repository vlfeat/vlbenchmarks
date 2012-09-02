% GENERICDATASET Abstract class for a generic dataset

classdef genericDataset < handle
  properties (SetAccess=protected, GetAccess=public)
    datasetName = ''; % Name of the dataset
    numImages = 0 % Number of images in the dataset
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgIdx)
    % GETIMAGEPATH Get path of an image from the dataset
    %   IMG_PATH = getImagePath(IMG_IDX) Returns path IMG_PATH of an
    %   image with id IMG_IDX \in [1:numImages]
  end
  
  methods
    function signature = getImagesSignature(obj)
    % GETIMAGESSIGNATURE Get signature of all images in the dataset
    %   SIGN = getImagesSignature() Returns signature of all the images
    %   in the dataset. Signature consist from the dataset name and
    %   MD5 of all images file signatures (see help `getFileSignature`).
      import helpers.*;
      imgSignatures = '';
      for imgIdx = 1:obj.numImages
        imgPath = obj.getImagePath(imgIdx);
        sign = fileSignature(imgPath);
        imgSignatures = strcat(imgSignatures, sign);
      end
      
      signature = ['dataset_' obj.datasetName CalcMD5.CalcMD5(imgSignatures)];
    end
  end
end % -------- end of class ---------
