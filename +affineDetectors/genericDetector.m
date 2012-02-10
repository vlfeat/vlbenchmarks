% This abstract class defines the interface for a generic affine interest point
% detector. It inherits from the handle class, so that means you can maintain
% state inside an object of this class.

classdef genericDetector < handle
  properties (SetAccess=private, GetAccess=public)
    % None here yet, the subclasses will define if needed
  end

  properties (SetAccess=private, GetAccess=private)
    detectorName % Set this in the constructor to use the name for plotting
    % purposes, else it will be set to a default value
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

  methods
    % This function returns the name of the detector used
    function name = getName(obj)
      if(isempty(obj.detectorName))
        name = class(obj);
      else
        name = obj.detectorName;
      end
    end

  end % ------- end of methods --------

end % -------- end of class ---------
