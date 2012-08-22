function score = computeEllipseOverlap(f1, f2)
% ELLOVERLAP
%
%

import benchmarks.*;
import benchmarks.helpers.*;

S1 = reshape(f1([3 4 4 5]), 2, 2) ;
S2 = reshape(f2([3 4 4 5]), 2, 2) ;
A1 = inv(S1) ;
A2 = inv(S2) ;
T1 = f1(1:2) ;
T2 = f2(1:2) ;

% translate to the origin (more stable)
t = mean([T1 T2],2) ;
T1 = T1 - t ;
T2 = T2 - t ;

% get conic matrices
C1 = [A1, -A1*T1 ; -T1'*A1, T1'*A1*T1-1];
C2 = [A2, -A2*T2 ; -T2'*A2, T2'*A2*T2-1];

% --------------------------------------------------------------------
%                                             Find intersection points
% --------------------------------------------------------------------

X = zeros(3,0) ;
lam = eig(C1,C2)' ;

for i=find(imag(lam) == 0)
  R = C1 - lam(i) * C2 ;
  [u, v] = factorDegConic(R) ;

  if ~isempty(u)
    X = [X realIntConic(C1, u)] ;
  end
  if ~isempty(v)
    X = [X realIntConic(C1, v)] ;
  end
end

if ~isempty(X)
  X = X(1:2,:) ./ repmat(X(3,:),2,1) ;
end

% sort intersection points anti-clockwise
x_star = X(1,:) ;
y_star = X(2,:) ;
x = x_star - mean(x_star) ;
y = y_star - mean(y_star) ;
[ang, perm] = sort(atan2(y, x)) ;
X = X(:, perm) ;

% remove duplicate intersection points
[drop, perm] = sort(abs(ang - circshift(ang,[0,1]))) ;
X(:, perm(1:end-4)) = [] ;
x_star = X(1,:) ;
y_star = X(2,:) ;

if 0
  figure(1); clf;
  hold on ;
  S1 = inv(A1) ;
  S2 = inv(A2) ;
  plotframe([T1; S1(1,1);S1(1,2);S1(2,2)]) ;
  plotframe([T2; S2(1,1);S2(1,2);S2(2,2)]) ;
  plotframe(X,'rx','markersize',20) ;
end

% --------------------------------------------------------------------
%                                                        Compute areas
% --------------------------------------------------------------------

area1 = allArea(A1) ;
area2 = allArea(A2) ;

if size(X,2) == 0

  % no intersection; check for containment
  if (T2-T1)' * A1 * (T2 - T1) < 1 | (T1-T2)' * A2 * (T1 - T2) < 1
    intersArea = min(area1, area2) ;
  else
    intersArea = 0 ;
  end

else
  % sort intersection points clockwise
  x = x_star - mean(x_star) ;
  y = y_star - mean(y_star) ;
  [ang, perm] = sort(atan2(y, x)) ;

  x = x_star(perm) ;
  y = y_star(perm) ;
  X = [x;y] ;

  if size(x_star,2) == 2

    % two intersections only
    out1 = min(outerArea(A1, T1, X(:,1), X(:,2)), ...
               outerArea(A2, T2, X(:,1), X(:,2))) ;
    out2 = min(outerArea(A1, T1, X(:,2), X(:,1)), ...
               outerArea(A2, T2, X(:,2), X(:,1))) ;
    intersArea = out1 + out2 ;

  elseif size(x_star,2) == 4

    out1 = min(outerArea(A1, T1, X(:,1), X(:,2)), ...
               outerArea(A2, T2, X(:,1), X(:,2))) ;
    out2 = min(outerArea(A1, T1, X(:,2), X(:,3)), ...
               outerArea(A2, T2, X(:,2), X(:,3))) ;
    out3 = min(outerArea(A1, T1, X(:,3), X(:,4)), ...
               outerArea(A2, T2, X(:,3), X(:,4))) ;
    out4 = min(outerArea(A1, T1, X(:,4), X(:,1)), ...
               outerArea(A2, T2, X(:,4), X(:,1))) ;

    in = x .* circshift(y, [0, -1]) - circshift(x, [0, -1]) .* y ;
    intersArea = out1 + out2 + out3 + out4 + sum(in) / 2 ;
  end
end

unionArea = area1 + area2 - intersArea ;
score = intersArea / unionArea ;

%disp('area of the intersection') ;
%disp(intersArea)

%disp('area of the unuon') ;
%disp(unionArea)

if 0
  u = randn(2, 1) ;
  x = u(1) ;
  y = u(2) ;
  disp((u - T1)' * A1 * (u - T1) - 1) ;
  disp(x.^2 * polyval(a2, y) + x * polyval(a1, y) + polyval(a0, y)) ;
  disp((u - T2)' * A2 * (u - T2) - 1) ;
  disp(x.^2 * polyval(b2, y) + x * polyval(b1, y) + polyval(b0, y)) ;
end

% --------------------------------------------------------------------
function [a2, a1, a0] = collectX(A, T)
% --------------------------------------------------------------------

a2 = A(1,1) ;

a1 = [A(1,2) + A(2,1), ...
      - 2 * T(1) * A(1,1) - T(2) * (A(1,2) + A(2,1)) ];

a0 = [A(2,2), ...
      - 2 * T(2) * A(2,2) - T(1) * (A(1,2) + A(2,1)), ...
      T(1) * T(2) * (A(1,2) + A(2,1)) + T(2)^2 * A(2,2) + T(1)^2 * A(1,1) - 1] ;

% --------------------------------------------------------------------
function area = outerArea(A, T, X1, X2)
% --------------------------------------------------------------------

X1 = X1 - T ;
X2 = X2 - T ;

[V, D] = eig(A) ;
if det(V) < 0
  V(1,:) = - V(1,:) ;
end
Ds = diag(sqrt(diag(D))) ;
L = Ds * V ;

X1_ = L * X1 ;
X2_ = L * X2 ;

a1 = atan2(X1_(2), X1_(1)) ;
a2 = atan2(X2_(2), X2_(1)) ;
a  = mod(a2 - a1 + 4*pi, 2 * pi) ;
%if a > pi, a = 2*pi - a ; end

area = (a / 2 - cos(a/2) * sin(a/2)) / det(L) ;

% --------------------------------------------------------------------
function area = allArea(A)
% --------------------------------------------------------------------

d = eig(A) ;
area = pi / sqrt(prod(d)) ;
