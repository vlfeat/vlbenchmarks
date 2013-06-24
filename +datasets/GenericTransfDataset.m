classdef GenericTransfDataset < datasets.GenericDataset
% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
%   known linear geometric transformation (for evaluating affine 
%   detectors). This class defines abstract method getTransformation(imgNo)
%   which must be implemented by all its subclasses.

% Author: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=protected, GetAccess=public)
    % Setting these properties is not mandatory however are usefull in 
    % functions for plotting results.
    ImageNames % Labels of images, e.g. degree of transformation
    ImageNamesLabel % Label of image names, e.g. type of transformation
  end

  methods(Abstract)
    [geometry] = getSceneGeometry(obj,imgNo) 
    % GETSCENEGEOMETRY Get transformation between an image and ref. image.
    %   TF = getTransformation(IMG_NO) Return the 3x3 homography TF from 
    %   image 1 to image IMG_NO.
  end
end
