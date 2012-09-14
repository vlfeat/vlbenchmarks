classdef GenericTransfDataset < datasets.GenericDataset
% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
%   known linear geometric transformation (for evaluating affine 
%   detectors). This class defines abstract method getTransformation(imgNo)
%   which must be implemented by all its subclasses.

% AUTORIGHTS
  properties (SetAccess=protected, GetAccess=public)
    % Setting these properties is not mandatory however are usefull in 
    % functions for plotting results.
    imageNames % Labels of images, e.g. degree of transformation
    imageNamesLabel % Label of image names, e.g. type of transformation
  end

  methods(Abstract)
    tf = getTransformation(obj,imgNo) 
    % GETTRANSFORMATION Get transformation between an image and ref. image.
    %   TF = getTransformation(IMG_NO) Return the 3x3 homography TF from 
    %   image 1 to image IMG_NO.
  end
end % -------- end of class ---------
