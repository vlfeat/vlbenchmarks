function [ K ] = anisotropicGauss( S, varargin )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
import helpers.*;

if size(S) ~= [2 2], error('Invariance mat. must be of size 2x2.'); end;
if S ~= S', error('Invariance mat. must be symetric.'); end;
if eig(S) < 0, error('Invariance matrix must be positive definite.'); end;

opts.sizeMultFact = 3;
opts = vl_argparse(opts,varargin);

filterSize = ceil([sqrt(S(1,1)) sqrt(S(2,2))].*opts.sizeMultFact)*2+1;
center = ceil(filterSize./2);
[y,x]=meshgrid(1:filterSize(2),1:filterSize(1)) ;
x = x - center(1); y = y - center(2);
u = [x(:)';y(:)'];
sU = exp(-0.5.*sum((u'/S)'.*u))./2/pi/sqrt(det(S));
K = reshape(sU, filterSize);

end

