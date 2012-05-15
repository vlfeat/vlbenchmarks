% VLFEATFRAMEDET class to wrap around the VLFeat Frame det implementation
%
%   obj = affineDetectors.vlFeatHessian('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class wraps aronud the Hessian implementation of VLFeat
%
%   The options to the constructor are the same as that for vl_hessian
%   See help vl_hessian to see those options and their default values.
%
%   See also: vl_framedet


classdef vlFeatFramedet < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % See help vl_mser for setting parameters for vl_mser
    vl_framedet_arguments
    binPath
    response_function
    frame_type
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = vlFeatFramedet(response_func, frame_type, varargin)
      obj.detectorName = [response_func, ' ', frame_type,' (vlFeat)'];
      obj.vl_framedet_arguments = varargin;
      obj.response_function = response_func;
      obj.frame_type = frame_type;
      obj.calcDescs = true;
      obj.binPath = which('vl_framedet');
    end

    function [frames descs] = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = single(img); % If not already in uint8, then convert

      if nargout == 2
        [frames descs] = vl_framedet(obj.response_function,obj.frame_type,...
                                     img,obj.vl_framedet_arguments{:});
      elseif nargout == 1
        [frames] = vl_framedet(obj.response_function,obj.frame_type,...
                               img,obj.vl_framedet_arguments{:});
      end
       
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'...
              obj.response_function ';' obj.frame_type ';'...
              evalc('disp(obj.vl_framedet_arguments)')];
    end

  end
end
