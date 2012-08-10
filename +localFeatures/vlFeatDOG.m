% VLFEATDOG class to wrap around the VLFeat DOG detector implementation
%
%   obj = affineDetectors.vlFeatDOG('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class wraps aronud the Difference of Gaussian (DOG) implementation
%   of VLFeat that is used as a detector for computing SIFT descriptors
%
%   The options to the constructor are the same as that for vl_sift
%   See help vl_sift to see those options and their default values.
%
%   See also: vl_sift

classdef vlFeatDOG < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for vl_sift
    % See help vl_sift for description of these properties
    vl_sift_arguments
    binPath
  end

  methods
    % The constructor is used to set the options for vl_sift call
    % See help vl_sift for possible parameters
    % This varargin is passed directly to vl_sift
    function obj = vlFeatDOG(varargin)
      obj.detectorName = 'DOG(vlFeat)';
      obj.vl_sift_arguments = varargin;
      obj.calcDescs = true;
      obj.binPath = which('vl_sift');
    end

    function [frames descs] = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2single(img);

      if nargout == 1
        [frames] = vl_sift(img,obj.vl_sift_arguments{:});
      elseif nargout == 2
        [frames descs] = vl_sift(img,obj.vl_sift_arguments{:});
      end
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'...
              evalc('disp(obj.vl_sift_arguments)')];
    end

  end
end
