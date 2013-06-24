function overlap =  computeEllipseOverlap(vggA,vggB)
% COMPUTEELLIPSEOVERLAP Computes ellipse overlap
%   OVERLAP = COMPITEELLIPSEOVERLAP(VGGA, VGGB) calls Kristian
%   Mikolajczyk ellipse overlap function and returns overlap ratio of
%   the elliptical frames ELL1 and ELL2.

import consistencyModels.homography.*;

[w, tw, d, td] = mexComputeEllipseOverlap(vggA, vggB, -1);

overlap = 1 - tw / 100 ;

