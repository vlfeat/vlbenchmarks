function [eeig,eigvec] = ellipseEigen(f)
% ELLEIGEN
%
% http://www.ahinson.com/algorithms/Sections/Mathematics/Eigensolution2x2.pdf
% http://www.math.harvard.edu/archive/21b_fall_04/exhibits/2dmatrices/index.html

numFrames = size(f,2);
eeig = zeros(2,numFrames);
eigvec = zeros(4,numFrames);

for i=1:numFrames
  [eigVec eigVal] = eig([f(3:4,i)';f(4:5,i)']);
  eeig(:,i) = [eigVal(1);eigVal(4)];
  eigvec(:,i) = [eigVec(:,1);eigVec(:,2)];
end
% The former code is numerically unstable...
%f = f+eps;

%tr = f(3,:) + f(5,:) ;
%dt = f(3,:) .* f(5,:) - f(4,:) .* f(4,:) ;
%dl = sqrt(tr .* tr - 4 * dt) ;
%eeig = .5 * [tr - dl ; tr + dl] ;

%nEl = size(f,2);
%vec1 = [ones(1,nEl);zeros(1,nEl)];
%vec2 = [zeros(1,nEl);ones(1,nEl)];

%nonDiag = (f(4,:)~=0);

%vec1(1,nonDiag) = f(4,nonDiag);
%vec1(2,nonDiag) = eeig(1,nonDiag)-f(3,nonDiag);

%vec2(1,nonDiag) = f(4,nonDiag);
%vec2(2,nonDiag) = eeig(2,nonDiag)-f(3,nonDiag);

%norm1 = sqrt(sum(vec1.*vec1,1));
%norm2 = sqrt(sum(vec2.*vec2,1));

%vec1 = bsxfun(@rdivide,vec1,norm1);
%vec2 = bsxfun(@rdivide,vec2,norm2);

%eigvec = [vec1;vec2];
