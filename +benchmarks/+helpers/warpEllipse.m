function well = warpEllipse(H, ell)
% warpEllipse  Warp elliptical frames through homography
%
%   Author:: Andrea Vedaldi
well = zeros(size(ell));
for i=1:size(ell,2)
  S = [ell(3,i) ell(4,i) 0 ; ell(4,i)  ell(5,i) 0 ; 0 0 -1] ;
  T = [1 0 ell(1,i) ; 0 1 ell(2,i) ; 0 0 1] ;

  M = H * T * S * T' * H' ;
  M = - M / M(3,3) ;

  t_ = - M(1:2,3) ;
  S_ = M(1:2,1:2) + t_*t_' ;

  well(:,i) = [t_ ; S_([1;2;4])] ;
end
