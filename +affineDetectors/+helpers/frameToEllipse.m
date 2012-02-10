function g = frameToEllipse(f)
% FRAMETOELL

switch size(f, 1)
  case 2+2
    g(1:2,:) = f(1:2,:) ;
    g([3 5],:) =  [1;1] * (f(3,:) .* f(3,:)) ;

  case 2+3
    g = f ;

  case 2+4

  otherwise
    error('Unrecognized frame format') ;
end
