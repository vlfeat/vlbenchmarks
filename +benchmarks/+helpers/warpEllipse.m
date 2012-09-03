function well = warpEllipse(H, ell)
% WARPELLIPSE Warp elliptical frame through homography
%   WELL = WARPELLIPSE(H, ELL) warps the ellptical frame(s) ELL by
%   using the homography matrix H. The homography is assumed to be
%   expressed relative to a coordinate system with orgin in (0,0),
%   while the frames ELL are in MATLAB image coordinate system with
%   origin in (1,1).

%   Author: Andrea Vedaldi

% AUTORIGHTS

  % take out MATLAB 1,1 origin
  ell(1:2,:) = ell(1:2,:) - 1 ;
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

  % put back MATLAB 1,1 origin
  well(1:2,:) = well(1:2,:) + 1 ;
end
