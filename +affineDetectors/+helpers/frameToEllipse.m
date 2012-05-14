function g = frameToEllipse(f)
% FRAMETOELL
% Convert frame to unoriented ellipse. If the frame is already an ellipse
% does not do anything and in case of an oriented ellipse converts into
% unoriented.

switch size(f, 1)
  case 2+2
    g(1:2,:) = f(1:2,:); % The coordinates
    g([3 5],:) =  [1;1] * (f(3,:) .* f(3,:)) ;

  case 2+3
    g = f ;

  case 2+4
    g(1:2,:) = f(1:2,:); % The coordinates
    for k=1:size(f,2)
      A = reshape(f(3:6,k)',2,2)';
      E = A' * A;
      g(3:5,k) = [E(1,1) E(1,2) E(2,2)]';
    end
  otherwise
    error('Unrecognized frame format') ;
end
