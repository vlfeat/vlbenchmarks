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
    [geometry] = getSceneGeometry(obj,imgAIdx,imgBIdx) 
    % GETSCENEGEOMETRY Get transformation between an image and ref. image.
    %   SG = getTransformation(TEST_IMG_IDX) Return the scene geometry 
    %     which defines transformation between the default reference 
    %     image and tested image TEST_IMG_IDX. The definition of the 
    %     tested image depends on the dataset implementation.
    %   SG = getTransformation(REF_IMG_IDX, TEST_IMG_IDX) Returns the scene
    %     geometry between the REF_IMG_IDX and TEST_IMG_IDX.
  end
end
