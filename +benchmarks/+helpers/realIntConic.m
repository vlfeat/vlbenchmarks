function X = realIntConic(C, l)
%
%

X = zeros(3,0) ;

if any(imag(l))
  return
end

if l(1) == 0 & l(2) == 0
  return
end

e3 = [0;0;1] ;
u = cross(l, e3) ;
v = cross(l, u) ;
p = v / v(3) ;

a = u.' *  C * u ;
b = u.' *  C * p ;
c = p.' *  C * p ;

delta = b^2 - a*c ;

if delta < 0
  return
end

d = sqrt(delta) ;
lam = (- b + [d, -d]) / a ;
X = u * lam + [p, p] ;
