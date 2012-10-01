function g = frameToEllipse(f)
% FRAMETOELLIPLSE converts frames to ellpises
%   ELL = FRAMETOELLIPSE(F) converts the specified frames F to unoriented
%   ellipses ELL. If the frame is already an ellipse does not do anything
%   and in case of an oriented ellipse converts into unoriented.

% Author: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS
if isempty(f)
  g=[];
  return;
end

switch size(f, 1)
  case 2+1 % Disc
    g(1:2,:) = f(1:2,:); % center
    g([3 5],:) =  [1;1] * (f(3,:) .* f(3,:)) ;

  case 2+2 % Oriented disc
    g(1:2,:) = f(1:2,:); % center
    g([3 5],:) =  [1;1] * (f(3,:) .* f(3,:)) ;

  case 2+3 % Ellipse (unoriented)
    g = f ;

  case 2+4 % Oriented ellipse - remove orientation
    g(1:2,:) = f(1:2,:); % center
    for k=1:size(f,2)
      A = reshape(f(3:6,k)',2,2)';
      E = A' * A;
      g(3:5,k) = [E(1,1) E(1,2) E(2,2)]';
    end

  otherwise
    error('Unrecognized frame format') ;
end
