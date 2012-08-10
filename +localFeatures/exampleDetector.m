% EXAMPLEDETECTOR Example class implementing a generic detector
%   obj = affineDetectors.exampleDetector();
%   obj.detectPoints(img);
%
%   This is an example class that demonstrates how to create a trivial
%   interest point detector. Modify it to wrap around your own detector
%   implementation. This class implements the genericDetector interface.

classdef exampleDetector < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % Create two example parameters
    exampleParameter1 = 0.5;
    exampleParameter2 = true;
  end

  methods
    % The constructor is set the parameters, this constructor
    % shows how to accept arguments in the standard matlab way
    %
    function obj = exampleDetector(varargin)
      obj.detectorName = 'Example'; % This is an inherited property
      opts.exampleParameter1 = 0.5; opts.exampleParameter2 = true;
      opts = vl_argparse(opts,varargin); % See help vl_argparse to understand
      obj.exampleParameter1 = opts.exampleParameter1;
      obj.exampleParameter2 = opts.exampleParameter2;
    end

    % This function wraps around your feature detector implementation
    % In this example, this is just a trivial detector, that outputs interest
    % points on a uniform 50x50 grid
    function frames = detectPoints(obj,img)
      [h w nCh] = size(img);
      xCentres = [6:50:w];
      yCentres = [6:50:h];
      [xCentres,yCentres] = meshgrid(xCentres,yCentres);

      frames = zeros(5,numel(xCentres));
      frames(1,:) = xCentres(:);
      frames(2,:) = yCentres(:);
      frames(3,:) = (25*25); % Circle of radius 5
      frames(4,:) = 0;       % Circle of radius 5
      frames(5,:) = (25*25); % Circle of radius 5
    end

  end
end
