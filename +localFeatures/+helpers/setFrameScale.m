function frames = setFrameScale(frames, scales)

% Authors: Karel Lenc

% AUTORIGHTS
import localFeatures.helpers.*;

if isempty(frames)
  frames = [];
  return;
end

if size(frames,2) ~= numel(scales)
  error('Number of frames and scales must be the same');
end

switch size(frames,1)
  case {3,4}
    frames(3,:) = scales;
  case 5
    det = prod(frames([3 5],:)) - frames(4,:).^2;
    if det >= 0
      % new det should be scales^4 and multiplying matrix by a will change
      % determinant with a^2...
      ratio = scales.^2/sqrt(det);
      frames(3:5,:) = frames(3:5,:).*ratio;
    else
      error('Invalid ellipse matrix.');
    end
  case 6
    det = prod(frames([3 6],:)) - prod(frames([4 5],:));
    if det > 0
      % new det should be scales^2 and multiplying matrix by a will change
      % determinant with a^2...
      ratio = scales/sqrt(det);
      frames(3:6,:) = frames(3:6,:).*ratio;
    else
      error('Invalid affine transformation.');
    end
  otherwise
na    error('Invalid frame');
end
end
