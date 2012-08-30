% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
% known linear geometric transformation for evaluating affine detectors.

classdef genericTransfDataset < datasets.genericDataset
  properties (SetAccess=protected, GetAccess=public)
    imageNames % Labels of images
    imageNamesLabel % Definition of the transformations
  end

  methods(Abstract)
    tfs = getTransformation(obj,imgIdx) % Return the 3x3 homography
    % from image 1 to image imgIdx
  end
end % -------- end of class ---------
