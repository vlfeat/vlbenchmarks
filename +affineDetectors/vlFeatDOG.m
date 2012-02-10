% This class implements the genericDetector interface. The implementation
% wraps around the vlFeat implementation of DOG region detection.

classdef vlFeatDOG < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for vl_sift
    % See help vl_sift for description of these properties
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    function obj = vlFeatDOG(varargin)
      obj.detectorName = 'vlFeatDOG';
    end

    function frames = detectPoints(obj,img)
      img = rgb2gray(img);
      img = im2single(img);

      frames = vl_sift(img);
    end

  end
end
