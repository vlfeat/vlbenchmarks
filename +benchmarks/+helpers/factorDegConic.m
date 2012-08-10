function [u,v] = factorDegConic(C)
%
%
%

r = rank(C) ;

if r > 1
  B = - adj3(C) ;
  d = sqrt(diag(B)) ;

  s = B ./ ([d d d] + eps) ;
  [drop, best] = max(abs(s(:))) ;
  [i,j] = ind2sub([3 3], best) ;
  s = s(:,j) ./ s(i,j) ;

  z = s .* d ;
  D = C - vl_hat(z) ;

  [drop, best] = max(sum(abs(D))) ;
  u = D(:, best) ;

  [drop, best] = max(sum(abs(D.'))) ;
  v = D(best, :).' ;
else
  [drop, best] = max(sum(abs(C))) ;
  u = C(:, best) ;
  v = [] ;
end

function B = adj3(A)
B = [cross(A(:,2),A(:,3)), ...
     cross(A(:,3),A(:,1)), ...
     cross(A(:,1),A(:,2))] .' ;
