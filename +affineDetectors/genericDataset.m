% GENERICDATASET Abstract class for a generic dataset for evaluating
% affine detectors.
%
%   It inherits from the handle class, so that means you can
%   maintain state inside an object of this class. If you have to add your
%   own dataset, make sure it inherits from this class
%   (see +affineDetectors/vggDataset.m for a example)

classdef genericDataset < handle
  properties (SetAccess=protected, GetAccess=public)
    datasetName = 'empty';% Set this property in the constructor
    numImages = 0 % Set in constructor
    imageLabels; % Set in constructor, labels of images in graphs
    imageLabelsTitle; % Set in constructor, xtitle
  end

  properties (SetAccess=public, GetAccess=public)
    % None here
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgIdx) % Return the full image
    % path of image number imgIdx in the dataset
    tfs = getTransformation(obj,imgIdx) % Return the 3x3 homography
    % from image 1 to image imgIdx
  end
  
  methods
    function sign = signature(obj)
    % SIGNATURE
    % Returns unique signature for detector parameters.
    %
    % This function is used for caching detected results. When the detector
    % parameters had changed, the signature must be different as well.
    
      sign_c = cell(1,obj.numImages);
      for i=1:obj.numImages
        img_fname = obj.getImagePath(i);
        img_sign = commonFns.file_signature(img_fname);
        sign_c{i} = [img_sign ';'];
      end
    
      sign = cell2mat(sign_c);
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
