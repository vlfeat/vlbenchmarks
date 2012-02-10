function result = matchEllipses(f1, f2, varargin)
% EVALFRAMESTABILITY
%
%  EVAL.NEIGH : for each F2 frame, the list of F1 neighbors
%
%  If no rescaling is applied the function is symmetric.
%
%  With rescaling, the frames of F2 are used to fix the scaling factors.
%
%  Author:: Andrea Vedaldi

import affineDetectors.*;

conf_.normalizeFrames = true ;
conf = vl_argparse(conf_, varargin) ;

% eigenvalues (radii squared)
e1 = helpers.ellipseEigen(f1) ;
e2 = helpers.ellipseEigen(f2) ;

% areas
a1 = pi * sqrt(prod(e1,1)) ;
a2 = pi * sqrt(prod(e2,1)) ;

% radius enclosing circle
r1 = sqrt(e1(2,:)) ;
r2 = sqrt(e2(2,:)) ;

N1 = size(f1,2) ;
N2 = size(f2,2) ;
neighs = cell(1,N2) ;
scores = cell(1,N2) ;

for i2 = 1:N2
  %fprintf('%.2f %%\r', i2/N2*100) ;

  s = 30 / sqrt(a2(i2) / pi)  ;

  canOverlap = sqrt(vl_alldist2(f2(1:2, i2), f1(1:2,:))) < 4 * sqrt(a2(i2) / pi) ;
  maxOverlap = min(a2(i2), a1) ./ max(a2(i2), a1) .* canOverlap ;
  neighs{i2} = find(maxOverlap > 0.3) ;

  S = diag([1 1 s^2 s^2 s^2]) ;
  for n = 1:length(neighs{i2})
    i1 = neighs{i2}(n) ;
    z = helpers.computeEllipseOverlap_slow(S * f2(:, i2), S * f1(:, i1)) ;
    scores{i2}(n) = z ;

    if z > 1
      figure(100) ; clf ;
      vl_plotframe(S * f2(:, i2), 'g') ; hold on ;
      vl_plotframe(S * f1(:, i1), 'r') ;
      text(f1(1,i1),f1(2,i1), sprintf('%.2f %%', scores{i2}(n) * 100)) ;
      axis equal ;
      drawnow
      pause
    end
  end

end

result.neighs = neighs ;
result.scores = scores ;
