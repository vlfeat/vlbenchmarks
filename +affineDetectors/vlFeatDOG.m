% This class implements the genericDetector interface. The implementation
% wraps around the vlFeat implementation of DOG region detection.

classdef vlFeatDOG < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for vl_sift
    % See help vl_sift for description of these properties
    vl_sift_arguments
  end

  methods
    % The constructor is used to set the options for vl_sift call
    % See help vl_sift for possible parameters
    % This varargin is passed directly to vl_sift
    function obj = vlFeatDOG(varargin)
      obj.detectorName = 'vlFeatDOG';
      obj.vl_sift_arguments = varargin;
    end

    function frames = detectPoints(obj,img)
      img = rgb2gray(img);
      img = im2single(img);

      frames = vl_sift(img,obj.vl_sift_arguments{:});
    end

  end
end
