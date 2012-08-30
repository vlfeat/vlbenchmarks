function [eeig,eigvec] = ellipseEigen(f)
% ELLIPSEEIGEN Calculates eigen values and vectors from ell. frames
%   [EIG EIGVEC] = ellipseEigen(F) Calculated eigen values EIG and 
%    eigen vectors EIGVEC of ellipse matrix E given by an ellipse 
%    frame F:
%
%    E = [ F(3,.) F(4,.) ]
%        [ F(4,.) F(5,.) ]
%
%    s.t. 
%      E * EIGVEC = EIGVEC * diag(EIG)
%

numFrames = size(f,2);
eeig = zeros(2,numFrames);
eigvec = zeros(4,numFrames);

for i=1:numFrames
  [eigVec eigVal] = eig([f(3:4,i)';f(4:5,i)']);
  eeig(:,i) = [eigVal(1);eigVal(4)];
  eigvec(:,i) = [eigVec(:,1);eigVec(:,2)];
end

% NOTE vector solution removed as it was unstable.
end