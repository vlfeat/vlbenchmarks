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

% Authors: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS

numFrames = size(frames,2);
eigval = zeros(2,numFrames);
eigvec = zeros(4,numFrames);

for i=1:numFrames
  [V, D] = eig(reshape(frames([3 4 4 5],i),2,2)) ;
  eigvec(:,i) = V(:) ;
  eigval(:,i) = D([1 4]) ;
end
