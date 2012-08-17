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

classdef vlFeatDOG < localFeatures.genericLocalFeatureExtractor
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
      detectorName = 'DOG(vlFeat)';
      obj = obj@localFeatures.genericLocalFeatureExtractor(detectorName,varargin);
      obj.vl_sift_arguments = obj.configureLogger(obj.detectorName,varargin);
      obj.binPath = which('vl_sift');
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      obj.info('computing frames for image %s.',getFileName(imagePath));
      
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2single(img);

      if nargout == 1
        [frames] = vl_sift(img,obj.vl_sift_arguments{:});
      elseif nargout == 2
        [frames descriptors] = vl_sift(img,obj.vl_sift_arguments{:});
      end
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';'...
              helpers.cell2str(obj.vl_sift_arguments)];
    end

  end
end
