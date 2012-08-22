function overlap =  computeEllipseOverlap_slow(vggA,vggB)
% ELLOVERLAP_SLOW
%
%

import benchmarks.*

[w, tw, d, td] = helpers.mexComputeEllipseOverlap(vggA, vggB, -1) ; % This mex file
% is borrowed from Kristians code, just renamed it

overlap = 1 - tw / 100 ;

