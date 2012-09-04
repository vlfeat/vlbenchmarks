function well = warpEllipse(H, ell, varargin)
% warpEllipse  Warp elliptical frames through homography
%   WELL = WARPELLIPSE(H,ELL) Warps ellipse ELL to WELL using linear 
%     transformation H.
%   WELL = WARPELLIPSE(H,ELL,'OptionName',OptionValue) Allows to specify
%     further options.
%
% Accpeted Options:
%   Method :: ['standard']
%     Specify the numerical method used for ellipse warping. Allowed 
%     options are 'standard' and 'km' which is the method used in 
%     the IJCV2004 benchmark.
%
%   Author:: Andrea Vedaldi

import helpers.*;
opts.method = 'standard';
opts = vl_argparse(opts, varargin);

well = zeros(size(ell));
for i=1:size(ell,2)
  switch opts.method
    case 'standard'
    S = [ell(3,i) ell(4,i) 0 ; ell(4,i)  ell(5,i) 0 ; 0 0 -1] ;
    T = [1 0 ell(1,i) ; 0 1 ell(2,i) ; 0 0 1] ;

    M = H * T * S * T' * H' ;
    M = - M / M(3,3) ;

    t_ = - M(1:2,3) ;
    S_ = M(1:2,1:2) + t_*t_' ;

    well(:,i) = [t_ ; S_([1;2;4])] ;
    
    case 'km'
    % Kristian's Solution
    Mi1=[ell(3,i) ell(4,i);ell(4,i) ell(5,i)];
    x = ell(1,i); y = ell(2,i);
    h11=H(1); h12=H(4); h13=H(7);
    h21=H(2); h22=H(5); h23=H(8);
    h31=H(3); h32=H(6); h33=H(9);
    fxdx=h11/(h31*x+h32*y+h33)-(h11*x+h12*y+h13)*h31/(h31*x+h32*y+h33)^2;
    fxdy=h12/(h31*x+h32*y+h33)-(h11*x+h12*y+h13)*h32/(h31*x+h32*y+h33)^2;
    fydx=h21/(h31*x+h32*y+h33)-(h21*x+h22*y+h23)*h31/(h31*x+h32*y+h33)^2;
    fydy=h22/(h31*x+h32*y+h33)-(h21*x+h22*y+h23)*h32/(h31*x+h32*y+h33)^2;
    Aff=[fxdx fxdy;fydx fydy];

    %project to image 2
    l1=[ell(1,i),ell(2,i),1];
    l1_2=H*l1';
    l1_2=l1_2/l1_2(3);
    well(1,i)=l1_2(1);
    well(2,i)=l1_2(2);
    BMB=Aff*Mi1*Aff';
    well(3:5,i)=[BMB(1);BMB(2); BMB(4)];
    
    otherwise
      error('Invalid method.');
  end
end
end