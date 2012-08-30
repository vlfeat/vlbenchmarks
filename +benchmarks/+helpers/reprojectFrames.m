function [reprojFramesA,reprojFramesB] = reprojectFrames(framesA,framesB,tfs)
% REPROJECTFRAMES Reproject frames detected in images pair
%   through homography.
%   [REP_FRAMES_A REP_FRAMES_B] = reprojectFrames(FRAMES_A, FRAMES_B,
%      TF) Reproject FRAMES_A to REP_FRAMES_A using homography TF
%      and FRAMES_B to REP_FRAMES_B with homography inv(TF).
%      Before reprojection frames are converted to 0-starting
%      coordinates.
  import benchmarks.helpers.*;

  % Change from Matlab origin
  framesA(1:2,:) = framesA(1:2,:) - 1 ;
  framesB(1:2,:) = framesB(1:2,:) - 1 ;
  
  % Reproject
  reprojFramesA = warpEllipse(tfs,framesA) ;
  reprojFramesB = warpEllipse(inv(tfs),framesB) ;

  % Move reprojected frames back to Matlab origin
  reprojFramesA(1:2,:) = reprojFramesA(1:2,:) + 1 ;
  reprojFramesB(1:2,:) = reprojFramesB(1:2,:) + 1 ;
end