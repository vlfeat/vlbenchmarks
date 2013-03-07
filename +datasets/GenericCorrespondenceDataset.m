classdef GenericCorrespondenceDataset < datasets.GenericDataset
% GENERICTRANSFDATASET Abstract class for a generic dataset with images of 
%   known linear geometric transformation (for evaluating affine 
%   detectors). This class defines abstract method getTransformation(imgNo)
%   which must be implemented by all its subclasses.

% Author: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=protected, GetAccess=public)
    % Number of different labels within the category.
    NumLabels = 0;
    % Number of images for each label..
    NumScenes = 0;
    % Setting these properties is not mandatory however are usefull in 
    % functions for plotting results.
    ImageNames % Labels of images, e.g. degree of transformation
    ImageNamesLabel % Label of image names, e.g. type of transformation
  end


  methods(Abstract)


    imgId = getImageId(obj, sceneNo, labelNo)
    imgId = getReferenceImageId(obj, sceneNo, labelNo)

    [validFramesA validFramesB] = validateFrames(obj, imgAId, imgBId, framesA, framesB)
    % VALIDATEFRAMES Filter invalid frames from image A and B. validFramesA and
    % validFramesB contain indices of valid entries in framesA and framesB
    % respectively.
    
    overlaps = scoreFrameOverlaps(obj, imgAId, imgBId, framesA, framesB)
    % SCOREFRAMEOVERLAPS Calculate the groundt truth overlaps (if any) between
    % the two sets of frames for the two images imgAId and imgBId. The overlaps
    % are returned as a struct containing two fields. overlaps.neighs is a cell
    % array where overlaps.neighs{i} is an array of frame indices in framesB 
    % that overlap with framesA(:,i). frameOverlaps.scores is a cell array
    % where overlaps.scores{i}(j) contains an overlap measure between 
    % framesA(:,i) and framesB(:, overlaps{i}(j)).
  end

end
