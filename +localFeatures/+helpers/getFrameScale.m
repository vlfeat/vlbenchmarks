function scales = getFrameScale(frames)
% GETFRAMESSCALE Return scales of a frame
%   SCALE = GETFRAMESCALE(FRAME) When FRAME is a column vector of
%   2 < size(F,1) < 7 SCALE is scale (scalar) of the frame.
%
%   SCALES = GETFRAMESCALE(FRAMES) When FRAMES is a matrix of
%   2 < size(F,1) < 7 SCALES is a row vector of 
%   size(SCALES,2) = size(FRAMES,2) with frame scales.
%
%   For elliptic frames the scale is computed as square root of the
%   determinant of the affine transformation. This can be expressed as
%   square root of the ratio between the ellipse area and unit circle.

% Authors: Karel Lenc

% AUTORIGHTS
import localFeatures.helpers.*;

switch size(frames,1)
  case {3,4}
    scales = frames(3,:);
  case 5
    det = prod(frames([3 5],:)) - frames(4,:).^2;
    if det >= 0
      scales = sqrt(sqrt(det));
    else
      error('Invalid ellipse matrix.');
    end
  case 6
    det = prod(frames([3 6],:)) - prod(frames([4 5],:));
    if det > 0
      scales = sqrt(det);
    else
      error('Invalid affine transformation.');
    end
  otherwise
    error('Invalid frame');
end
end
