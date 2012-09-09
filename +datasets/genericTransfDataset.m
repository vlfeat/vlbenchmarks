% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
% known linear geometric transformation (for evaluating affine detectors).

classdef genericTransfDataset < datasets.genericDataset
  properties (SetAccess=protected, GetAccess=public)
    % Setting these properties is not mandatory however are usefull in 
    % functions for plotting results.
    imageNames % Labels of images, express degree of transformation
    imageNamesLabel % Definition of the type of transformations
  end

  methods(Abstract)
    tf = getTransformation(obj,imgNo) 
    % GETTRANSFORMATION Get transformation between an image and ref. image.
    %   TF = getTransformation(IMG_NO) Return the 3x3 homography TF from 
    %   image 1 to image IMG_NO.
  end
end % -------- end of class ---------
