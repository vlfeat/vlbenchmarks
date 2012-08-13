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

import benchmarks.*;

conf.normaliseFrames = true ;
conf.normaliseScale = 30 ;
conf = helpers.vl_argparse(conf, varargin) ;


% eigenvalues (radii squared)
[e1,eigVec1] = helpers.ellipseEigen(f1) ;
[e2,eigVec2] = helpers.ellipseEigen(f2) ;

vggEll1 = helpers.ellToVgg(f1,e1,eigVec1);
vggEll2 = helpers.ellToVgg(f2,e2,eigVec2);

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

if isempty(f1) || isempty(f2)
  result.neighs = neighs ;
  result.scores = scores ;
  return;
end

for i2 = 1:N2
  %fprintf('%.2f %%\r', i2/N2*100) ;

  s = conf.normaliseScale / sqrt(a2(i2) / pi)  ;

  canOverlap = sqrt(vl_alldist2(f2(1:2, i2), f1(1:2,:))) < 4 * sqrt(a2(i2) / pi);
  maxOverlap = min(a2(i2), a1) ./ max(a2(i2), a1) .* canOverlap ;
  neighs{i2} = find(maxOverlap > 0.3) ;

  %S = [1 1 s^2 s^2 s^2]';
  vggS = [1 1 1/s^2 1/s^2 1/s^2 s s s s]';

  if conf.normaliseFrames
    lhsEllipse = vggS.*vggEll2(:,i2);
    rhsEllipse = bsxfun(@times,vggEll1(:,neighs{i2}),vggS);
  else
    lhsEllipse = vggEll2(:,i2);
    rhsEllipse = vggEll1(:,neighs{i2});
  end
  scores{i2} = helpers.computeEllipseOverlap_slow(lhsEllipse,rhsEllipse,...
    -1)';

end

result.neighs = neighs ;
result.scores = scores ;
