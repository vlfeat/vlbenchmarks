function overlap =  computeEllipseOverlap_slow(a, b,vggA,vggB)
% ELLOVERLAP_SLOW
%
%

import affineDetectors.*

%a = elltovgg(a) ;
%b = elltovgg(b) ;
%scalingVector = [scale*ones(2,1);1/scale*ones(3,1);sqrt(scale)*ones(4,1)];

[w, tw, d, td] = helpers.mexComputeEllipseOverlap(vggA, vggB, -1) ; % This mex file
% is borrowed from Kristians code, just renamed it
overlap = 1 - tw / 100 ;

% --------------------------------------------------------------------
function ell = elltovgg(ell)
% --------------------------------------------------------------------

ell = [ell ; zeros(4, size(ell, 2))] ;

for i=1:size(ell,2)
  S = [ell(3,i) ell(4,i) ; ell(4,i) ell(5,i)] ;
  [V, D] = eig(S) ;
  Dinv = diag(1./(diag(D)+eps)) ;
  A = V * Dinv * V' ;
  ell([8 9],i) = sqrt(ell([3 5],i)) ;
  ell(3:5,i)   = A([1 2 4]) ;
  ell([6 7],i) = sqrt(D([1 4])) ;
end
