% This class implements the genericDetector interface. The implementation
% wraps around the vlFeat implementation of MSER region detection.

classdef vlFeatMser < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for vl_mser
    % See help vl_mser for description of these properties
    delta
    maxArea
    minArea
    maxVariation
    minDiversity
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    function obj = vlFeatMser(varargin)
      obj.delta = 5;
      obj.maxArea = 0.75;
      obj.minArea = 0; % This is not exactly the same as default vl_mser
      obj.maxVariation = 0.25;
      obj.minDiversity = 0.2;
    end

    function frames = detectPoints(obj,img)
      img = rgb2gray(img);
      img = im2uint8(img); % If not already in uint8, then convert

      [xx brightOnDarkFrames] = vl_mser(img,'delta',obj.delta,'maxArea',...
                                obj.maxArea,'minArea',obj.minArea, ...
                                'maxVariation',obj.maxVariation, ...
                                'minDiversity',obj.minDiversity);

      [xx darkOnBrightFrames] = vl_mser(255-img,'delta',obj.delta,'maxArea',...
                                obj.maxArea,'minArea',obj.minArea, ...
                                'maxVariation',obj.maxVariation, ...
                                'minDiversity',obj.minDiversity);

      frames = vl_ertr([brightOnDarkFrames darkOnBrightFrames]);
      sel = find(frames(3,:).*frames(5,:) - frames(4,:).^2 >= 1) ;
      frames = frames(:, sel) ;
    end

  end
end
