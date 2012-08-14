% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
% known linear geometric transformation for evaluating affine detectors.

classdef genericTransfDataset < genericDataset
  properties (SetAccess=protected, GetAccess=public)
    imageNames % Labels of images
    imageNamesLabel % Definition of the transformations
  end

  methods(Abstract)
    tfs = getTransformation(obj,imgIdx) % Return the 3x3 homography
    % from image 1 to image imgIdx
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
