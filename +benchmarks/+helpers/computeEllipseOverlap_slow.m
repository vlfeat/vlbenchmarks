function overlap =  computeEllipseOverlap_slow(vggA,vggB,normalise)
% ELLOVERLAP_SLOW
%
%

import benchmarks.*

norm_arg = double(normalise);

[w, tw, d, td] = helpers.mexComputeEllipseOverlap(vggA, vggB, norm_arg) ; % This mex file
% is borrowed from Kristians code, just renamed it

overlap = 1 - tw / 100 ;

