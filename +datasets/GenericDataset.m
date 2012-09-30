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

  properties (SetAccess=protected, GetAccess=protected, Hidden)
    ImageSignatures = {}; % Image signatures
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgNo)
    % getImagePath Get path of an image from the dataset    
    %   IMG_PATH = obj.getImagePath(IMG_NO) Returns path IMG_PATH of
    %   an image with number IMG_NO \in [1:NumImages]
  end

  methods
    function signatures = getImagesSignature(obj, imgs)
    % getImagesSignature Get signature of all images in the dataset
    %   SIGN = obj.getImagesSignature() Returns signature of all the
    %   images in the dataset. Signature consist from the dataset name
    %   and MD5 of all images file signatures.
    %
    %   SIGN = obj.getImagesSignature(IMGS) Returns signatures of images 
    %   with numbers IMGS.
    %
    %   Signatures are computed only once for an object and stored in a
    %   memory.
    %
    % See also: helpers.fileSignature
      import helpers.*;
      if nargin < 2, imgs = 1:obj.NumImages; end;
      if max(imgs) > obj.NumImages || min(imgs) < 1
        error('Invalid image numbers.');
      end
      if isempty(obj.ImageSignatures)
        % Compute the signatures
        obj.ImageSignatures = cell(1,obj.NumImages);
        for imgNo = 1:obj.NumImages
          imgPath = obj.getImagePath(imgNo);
          obj.ImageSignatures{imgNo} = fileSignature(imgPath);
        end
      end
      signatures = cell2str(obj.ImageSignatures(imgs));
      signatures = helpers.CalcMD5.CalcMD5(signatures);
    end
  end
end % -------- end of class ---------
