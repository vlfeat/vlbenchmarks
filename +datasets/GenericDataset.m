classdef GenericDataset < handle
% datasets.GenericDataset Abstract class for a generic dataset
%   This class defines only one abstract method getImagePath(imgNo) which
%   must be implemented by all its subclasses.

% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=protected, GetAccess=public)
    DatasetName = ''; % Name of the dataset
    NumImages = 0 % Number of images in the dataset
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgNo)
    % getImagePath Get path of an image from the dataset    
    %   IMG_PATH = obj.getImagePath(IMG_NO) Returns path IMG_PATH of
    %   an image with number IMG_NO \in [1:NumImages]
  end

  methods
    function signature = getImagesSignature(obj)
    % getImagesSignature Get signature of all images in the dataset
    %   SIGN = obj.getImagesSignature() Returns signature of all the
    %   images in the dataset. Signature consist from the dataset name
    %   and MD5 of all images file signatures (see help
    %   `getFileSignature`).
      import helpers.*;
      imgSignatures = '';
      for imgNo = 1:obj.NumImages
        imgPath = obj.getImagePath(imgNo);
        sign = fileSignature(imgPath);
        imgSignatures = strcat(imgSignatures, sign);
      end
      signature = ['dataset_' obj.DatasetName CalcMD5.CalcMD5(imgSignatures)];
    end
  end
end % -------- end of class ---------
