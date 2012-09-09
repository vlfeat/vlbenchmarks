% GENERICDATASET Abstract class for a generic dataset

classdef genericDataset < handle
  properties (SetAccess=protected, GetAccess=public)
    datasetName = ''; % Name of the dataset
    numImages = 0 % Number of images in the dataset
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgNo)
    % GETIMAGEPATH Get path of an image from the dataset
    %   IMG_PATH = getImagePath(IMG_NO) Returns path IMG_PATH of an
    %   image with number IMG_NO \in [1:numImages]
  end
  
  methods
    function signature = getImagesSignature(obj)
    % GETIMAGESSIGNATURE Get signature of all images in the dataset
    %   SIGN = getImagesSignature() Returns signature of all the images
    %   in the dataset. Signature consist from the dataset name and
    %   MD5 of all images file signatures (see help `getFileSignature`).
      import helpers.*;
      imgSignatures = '';
      for imgNo = 1:obj.numImages
        imgPath = obj.getImagePath(imgNo);
        sign = fileSignature(imgPath);
        imgSignatures = strcat(imgSignatures, sign);
      end
      
      signature = ['dataset_' obj.datasetName CalcMD5.CalcMD5(imgSignatures)];
    end
  end
end % -------- end of class ---------
