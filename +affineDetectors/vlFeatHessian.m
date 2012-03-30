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
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = vlFeatHessian(varargin)
      obj.detectorName = 'hessian-affine(vlFeat)';
      obj.vl_hessian_arguments = varargin;
    end

    function frames = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = single(img); % If not already in uint8, then convert

      [frames] = vl_hessian(img,obj.vl_hessian_arguments{:},'CalcAffine');

      %sel = find(frames(3,:).*frames(5,:) - frames(4,:).^2 >= 1) ;
      %frames = frames(:, sel) ;
    end

  end
end
