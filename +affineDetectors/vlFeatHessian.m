% VLFEATHESSIAN class to wrap around the VLFeat HESSIAN implementation
%
%   obj = affineDetectors.vlFeatHessian('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class wraps aronud the Hessian implementation of VLFeat
%
%   The options to the constructor are the same as that for vl_hessian
%   See help vl_hessian to see those options and their default values.
%
%   See also: vl_hessian


classdef vlFeatHessian < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % See help vl_mser for setting parameters for vl_mser
    vl_hessian_arguments
    binPath
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = vlFeatHessian(varargin)
      obj.detectorName = 'hessian-affine(vlFeat)';
      obj.vl_hessian_arguments = varargin;
      obj.calcDescs = true;
      obj.binPath = which('vl_hessian');
    end

    function [frames descs] = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = single(img); % If not already in uint8, then convert

      if nargout == 2
        [frames descs] = vl_hessian(img,obj.vl_hessian_arguments{:});
      elseif nargout == 1
        [frames] = vl_hessian(img,obj.vl_hessian_arguments{:});
      end
       
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'...
              evalc('disp(obj.vl_hessian_arguments)')];
    end

  end
end
