function overlap =  computeEllipseOverlap(vggA,vggB)
% COMPUTEELLIPSEOVERLAP Computes ellipse overlap 
%
%  OVERLAP = computeEllipseOverlap(VGG_FRAMEA, VGG_FRAMEB) calls
%    Kristian Mikolajczyk Ellipse overlap function and returns overlap
%    ratio of the ellipses VGG_FRAMEA and VGG_FRAMEB.
%
import benchmarks.*

% 
[w, tw, d, td] = helpers.mexComputeEllipseOverlap(vggA, vggB, -1);

overlap = 1 - tw / 100 ;

