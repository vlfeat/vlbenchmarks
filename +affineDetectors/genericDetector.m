% This abstract class defines the interface for a generic affine interest point
% detector. It inherits from the handle class, so that means you can maintain
% state inside an object of this class.

classdef genericDetector < handle
  properties (Abstract, SetAccess=private, GetAccess=public)
    % No properties
    % Instances of this class will define the properties they need
  end

  methods(Abstract)
    % The constructor of every class that inherits from this class
    % is expected to be used to set the options specific to that
    % detector

    frames = detectPoints(img)  % Expect a 3 channel(RGB) uint8 image to be
    % passed to this function. The actual detectPoints function should
    % handle transforming the img to grayScale/double etc.
    % Output:
    %   frames: 5 x nFrames array storing the output of affine detection.
    %   frames(1,:) stores the X-coordinates of the points
    %   frames(2,:) stores the Y-coordinates of the points
    %   frames(3,:) stores ?? TODO
    %   frames(4,:) stores ??
    %   frames(5,:) stores ??
  end
end
