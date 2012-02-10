function eeig = ellipseEigen(f)
% ELLEIGEN
%
%

tr = f(3,:) + f(5,:) ;
dt = f(3,:) .* f(5,:) - f(4,:) .* f(4,:) ;
dl = sqrt(tr .* tr - 4 * dt) ;
eeig = .5 * [tr - dl ; tr + dl] ;
