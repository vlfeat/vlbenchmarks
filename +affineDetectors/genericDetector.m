% GENERICDETECTOR Abstract class that defines the interface for a
%   generic affine interest point detector.
%
%   It inherits from the handle class, so that means you can maintain state
%   inside an object of this class. If you have to add your own detector make
%   sure it inherits this class.
%   (see +affineDetectors/exampleDetector.m for a simple example)

classdef genericDetector < handle
  properties (SetAccess=protected, GetAccess=public)
    isOk = true; % signifies if detector has been installed and runs ok on
    % this particular platform
    errMsg = ''; % If there is some failure in detector, this string stores it
    calcDescs = false; % If the detector yields descriptors
  end

  properties (SetAccess=public, GetAccess=public)
    detectorName % Set this property to use when plots are generated
  end

  methods(Abstract)
    % The constructor of every class that inherits from this class
    % is expected to be used to set the options specific to that
    % detector

    frames = detectPoints(img)  % Expect a 3 channel(RGB) uint8 image to be
    % passed to this function. The actual detectPoints function should
    % handle transforming the img to grayScale/double etc.
    % Output:
    %   frames: 3 x nFrames array storing the output regions as circles
    %     or
    %   frames: 5 x nFrames array storing the output regions as ellipses
    %
    %   frames(1,:) stores the X-coordinates of the points
    %   frames(2,:) stores the Y-coordinates of the points
    %
    %   if frames is 3 x nFrames, then frames(3,:) is the radius of the circles
    %   if frames is 5 x nFrames, then frames(3,:), frames(4,:) and frames(5,:)
    %   store respectively the S11, S12, S22 such that
    %   ELLIPSE = {x: x' inv(S) x = 1}.
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

  methods(Static)
    % Over-ride this function to delete data from the right location
    function cleanDeps()
      fprintf('No dependencies to delete for this detector class\n');
    end

    % Over-ride this function to download and install data in the right location
    function installDeps()
      fprintf('No dependencies to install for this detector class\n');
    end
  end

end % -------- end of class ---------
