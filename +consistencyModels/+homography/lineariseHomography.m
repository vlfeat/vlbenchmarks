function aff = lineariseHomography(H, pt)
% Author: Krystian Mikolajczyk

    x = pt(1,:); y = pt(2,:);
    h11=H(1); h12=H(4); h13=H(7);
    h21=H(2); h22=H(5); h23=H(8);
    h31=H(3); h32=H(6); h33=H(9);
    
    fxdx=h11/(h31*x+h32*y+h33)-(h11*x+h12*y+h13)*h31/(h31*x+h32*y+h33)^2;
    fxdy=h12/(h31*x+h32*y+h33)-(h11*x+h12*y+h13)*h32/(h31*x+h32*y+h33)^2;
    fydx=h21/(h31*x+h32*y+h33)-(h21*x+h22*y+h23)*h31/(h31*x+h32*y+h33)^2;
    fydy=h22/(h31*x+h32*y+h33)-(h21*x+h22*y+h23)*h32/(h31*x+h32*y+h33)^2;
    
    aff=[fxdx fxdy;fydx fydy];
end