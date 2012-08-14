% GENERICDATASET Abstract class for a generic dataset for evaluating 
% affine detectors.
%
%   It inherits from the handle class, so that means you can
%   maintain state inside an object of this class. If you have to add your
%   own dataset, make sure it inherits from this class

classdef genericDataset < handle
  properties (SetAccess=protected, GetAccess=public)
    datasetName = ''; % Set this property in the constructor
    numImages = 0 % Set in constructor
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgIdx) % Return the full image
    % path of image number imgIdx in the dataset
  end
  
  methods
    function signature = getImagesSignature(obj)
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

  methods(Static)
    % Over-ride this function to delete data from the right location
    function cleanDeps()
      fprintf('No dependencies to delete for this dataset class\n');
    end

    % Over-ride this function to download and install data in the right location
    function installDeps()
      fprintf('No dependencies to install for this dataset class\n');
    end

  end

end % -------- end of class ---------
