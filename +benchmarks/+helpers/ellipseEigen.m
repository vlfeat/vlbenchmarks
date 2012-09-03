function [eigval,eigvec] = ellipseEigen(frames)
% ELLIPSEEIGEN Computes the eigenvalues an eigenvectors for an ellipse
%   [EIGVAL EIGVEC] = ELLPISEEIGEN(FRAMES) calculates the eigenvalues
%   EIGVAL and eigenvectors EIGVEC of the elliptical frames
%   FRAMES. The covariance of an ellipse is given by
%
%    S = [FRAMES(3) FRAMES(4)]
%        [FRAMES(4) FRAMES(5)]
%
%   then EIGVAL contains the eigenvalues of this matrix and EIGVEC the
%   corresponding eigenvectors (stacked), such that
%
%     S * reshape(eigvec,2,2) = reshape(eigvec,2,2) * diag(eigval).
%
%   If FRAMES contains more than one elliptical frame, then EIGVEC
%   and EIGVAL have one column per frame.

% Author: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS

numFrames = size(f,2);
eigval = zeros(2,numFrames);
eigvec = zeros(4,numFrames);

for i=1:numFrames
  [eigvec(:,i), tmp] = eig([f(3:4,i)';f(4:5,i)']);
  eigval(:,i) = tmp([1 4])' ;
end
